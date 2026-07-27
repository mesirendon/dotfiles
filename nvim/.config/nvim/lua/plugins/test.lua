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
      return require("neotest-jest")({ jestCommand = "npm test --" })
    end,
  },
  {
    spec = "marilari88/neotest-vitest",
    build = function()
      return require("neotest-vitest")
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
