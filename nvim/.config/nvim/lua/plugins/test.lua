local function go_test_args()
  local args = {
    "-v",
    "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
  }

  -- -race requires CGO + a working C toolchain; probe with a real build
  -- to catch ABI/linker issues (common on Linux arm64 with Homebrew Go)
  vim.fn.system("go build -race -o /dev/null std 2>&1")
  if vim.v.shell_error == 0 then
    table.insert(args, 2, "-race")
  end

  return args
end

-- Adapter registry. To support a new language: add one entry here (and, if it
-- needs extra keymaps, an `ft_extras` entry in lua/config/testing.lua).
-- `spec` is the lazy plugin spec, `build` returns the configured adapter.
local adapters = {
  {
    spec = { "fredrikaverpil/neotest-golang", version = "*", branch = "main" },
    build = function()
      return require("neotest-golang")({ go_test_args = go_test_args() })
    end,
  },
  {
    spec = "nvim-neotest/neotest-python",
    build = function()
      return require("neotest-python")({ dap = { justMyCode = false } })
    end,
  },
  {
    spec = "nvim-neotest/neotest-jest",
    build = function()
      local jest_configs = { "jest.config.js", "jest.config.ts", "jest.config.mjs", "jest.config.cjs", "jest.config.json" }

      -- Directory of the nearest package.json: jest must run from the package,
      -- not nvim's cwd (a monorepo root would run the wrong `test` script).
      local function package_root(path)
        return vim.fs.root(path, "package.json")
      end

      return require("neotest-jest")({
        -- Let the adapter resolve node_modules/.bin/jest itself instead of
        -- `npm test --`, which drags in whatever the package's script adds.
        cwd = function(path)
          return path and package_root(path) or vim.fn.getcwd()
        end,
        -- The default only claims files when package.json lists `jest`
        -- directly (missing transitive installs from shared CI configs), and
        -- errors when nvim's cwd has no package.json. Look at the package
        -- itself instead: a jest config or an installed jest binary.
        isTestFile = function(file_path)
          if not file_path or not file_path:match("%.test%.[jt]sx?$") and not file_path:match("%.spec%.[jt]sx?$") then
            return false
          end
          local root = package_root(file_path)
          if not root then
            return false
          end
          for _, name in ipairs(jest_configs) do
            if vim.uv.fs_stat(root .. "/" .. name) then
              return true
            end
          end
          return vim.uv.fs_stat(root .. "/node_modules/.bin/jest") ~= nil
            and not vim.uv.fs_stat(root .. "/node_modules/.bin/vitest")
        end,
      })
    end,
  },
  {
    spec = "marilari88/neotest-vitest",
    build = function()
      local vitest = require("neotest-vitest")

      -- Vitest 4+ joins describe/test names with " > " when matching
      -- --testNamePattern, but the adapter joins them with a space, so running
      -- or debugging a single test skips everything. Rebuild the pattern to
      -- accept either separator (keeps Vitest <= 3 working too).
      local function escape(s)
        return (s:gsub("[%^%$%(%)%[%]%{%}%.%*%+%-%?|\\/]", "\\%0"):gsub(" ", "\\s"))
      end

      local function name_pattern(tree)
        local names = {}
        local node = tree
        while node and node:data().type ~= "file" and node:data().type ~= "dir" do
          table.insert(names, 1, escape(node:data().name))
          node = node:parent()
        end
        if #names == 0 then
          return nil
        end
        local pattern = "^\\s?" .. table.concat(names, "(?:\\s>\\s|\\s)")
        return tree:data().type == "test" and pattern .. "$" or pattern
      end

      local function rewrite(list, pattern)
        for i, arg in ipairs(list or {}) do
          if arg:find("^%-%-testNamePattern=") then
            list[i] = "--testNamePattern=" .. pattern
          end
        end
      end

      local build_spec = vitest.build_spec
      vitest.build_spec = function(args)
        local spec = build_spec(args)
        local pattern = spec and args.tree and name_pattern(args.tree)
        if pattern then
          rewrite(spec.command, pattern)
          -- The dap strategy copies the command into its own args list.
          rewrite(spec.strategy and spec.strategy.args, pattern)
        end
        return spec
      end

      return vitest
    end,
  },
  {
    spec = "nvim-neotest/neotest-plenary",
    build = function()
      return require("neotest-plenary")
    end,
  },
  -- Catch-all, must stay LAST: hands the filetypes below off to vim-test.
  {
    spec = "nvim-neotest/neotest-vim-test",
    build = function()
      return require("neotest-vim-test")({
        allow_file_types = { "ruby", "elixir", "php", "rust", "java", "cs" },
      })
    end,
  },
}

local function build_adapters()
  local built = {}
  for _, adapter in ipairs(adapters) do
    local ok, instance = pcall(adapter.build)
    if ok then
      table.insert(built, instance)
    else
      vim.notify(("neotest: skipping adapter (%s)"):format(instance), vim.log.levels.DEBUG, { title = "neotest" })
    end
  end
  return built
end

local specs = {
  {
    "nvim-neotest/neotest",
    event = "VeryLazy",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
    },
    config = function()
      local neotest = require("neotest")
      neotest.setup({
        adapters = build_adapters(),
        benchmark = {
          enabled = true,
        },
        consumers = {},
        default_strategy = "integrated",
        diagnostic = {
          enabled = true,
          severity = 1,
        },
        discovery = {
          concurrent = 0,
          enabled = true,
        },
        floating = {
          max_height = 0.6,
          max_width = 0.6,
          options = {},
        },
        highlights = {
          adapter_name = "NeotestAdapterName",
          border = "NeotestBorder",
          dir = "NeotestDir",
          expand_marker = "NeotestExpandMarker",
          failed = "NeotestFailed",
          file = "NeotestFile",
          focused = "NeotestFocused",
          indent = "NeotestIndent",
          marked = "NeotestMarked",
          namespace = "NeotestNamespace",
          passed = "NeotestPassed",
          running = "NeotestRunning",
          select_win = "NeotestWinSelect",
          skipped = "NeotestSkipped",
          target = "NeotestTarget",
          test = "NeotestTest",
          unknown = "NeotestUnknown",
          watching = "NeotestWatching",
        },
        icons = {
          child_indent = "│",
          child_prefix = "├",
          collapsed = "─",
          expanded = "╮",
          failed = "",
          final_child_indent = " ",
          final_child_prefix = "╰",
          non_collapsible = "─",
          notify = "",
          passed = "",
          running = "",
          running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
          skipped = "",
          unknown = "",
          watching = "",
        },
        jump = {
          enabled = true,
        },
        log_level = 3,
        output = {
          enabled = true,
          open_on_run = "short",
        },
        output_panel = {
          enabled = true,
          open = "botright split | resize 15",
        },
        projects = {},
        quickfix = {
          enabled = true,
          open = false,
        },
        run = {
          enabled = true,
        },
        running = {
          concurrent = true,
        },
        state = {
          enabled = true,
        },
        status = {
          enabled = true,
          signs = true,
          virtual_text = false,
        },
        strategies = {
          integrated = {
            height = 40,
            width = 120,
          },
        },
        summary = {
          animated = true,
          count = true,
          enabled = true,
          expand_errors = true,
          follow = true,
          mappings = {
            attach = "a",
            clear_marked = "M",
            clear_target = "T",
            debug = "d",
            debug_marked = "D",
            expand = { "<CR>", "<2-LeftMouse>" },
            expand_all = "e",
            help = "?",
            jumpto = "i",
            mark = "m",
            next_failed = "J",
            next_sibling = "j",
            output = "o",
            parent = "p",
            prev_failed = "K",
            prev_sibling = "k",
            run = "r",
            run_marked = "R",
            short = "O",
            stop = "u",
            target = "t",
            watch = "w",
          },
          open = "botright vsplit | vertical resize 50",
        },
        watch = {
          enabled = true,
          symbol_queries = {
            go = "        ;query\n        ;Captures imported types\n        (qualified_type name: (type_identifier) @symbol)\n        ;Captures package-local and built-in types\n        (type_identifier)@symbol\n        ;Captures imported function calls and variables/constants\n        (selector_expression field: (field_identifier) @symbol)\n        ;Captures package-local functions calls\n        (call_expression function: (identifier) @symbol)\n      ",
            javascript = '  ;query\n  ;Captures named imports\n  (import_specifier name: (identifier) @symbol)\n  ;Captures default import\n  (import_clause (identifier) @symbol)\n  ;Capture require statements\n  (variable_declarator \n  name: (identifier) @symbol\n  value: (call_expression (identifier) @function  (#eq? @function "require")))\n  ;Capture namespace imports\n  (namespace_import (identifier) @symbol)\n',
            lua = '        ;query\n        ;Captures module names in require calls\n        (function_call\n          name: ((identifier) @function (#eq? @function "require"))\n          arguments: (arguments (string) @symbol))\n      ',
            tsx = '  ;query\n  ;Captures named imports\n  (import_specifier name: (identifier) @symbol)\n  ;Captures default import\n  (import_clause (identifier) @symbol)\n  ;Capture require statements\n  (variable_declarator \n  name: (identifier) @symbol\n  value: (call_expression (identifier) @function  (#eq? @function "require")))\n  ;Capture namespace imports\n  (namespace_import (identifier) @symbol)\n',
            typescript = '  ;query\n  ;Captures named imports\n  (import_specifier name: (identifier) @symbol)\n  ;Captures default import\n  (import_clause (identifier) @symbol)\n  ;Capture require statements\n  (variable_declarator \n  name: (identifier) @symbol\n  value: (call_expression (identifier) @function  (#eq? @function "require")))\n  ;Capture namespace imports\n  (namespace_import (identifier) @symbol)\n',
          },
        },
      })
    end,
  },
}

-- Adapters are standalone lazy specs rather than neotest dependencies: several
-- of them require `neotest.lib` at module load, so force-loading one ahead of
-- neotest would make a cycle (adapter -> neotest -> config -> adapter). Loading
-- them only from neotest's own config, above, keeps the graph acyclic.
for _, adapter in ipairs(adapters) do
  local spec = type(adapter.spec) == "table" and vim.deepcopy(adapter.spec) or { adapter.spec }
  spec.lazy = true
  table.insert(specs, spec)
end

return specs
