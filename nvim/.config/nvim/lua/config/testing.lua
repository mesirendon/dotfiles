-- Universal test (<leader>t) and debug (<leader>d) menus.
--
-- These are language-agnostic: neotest picks the adapter that claims the
-- current file (see lua/plugins/test.lua) and nvim-dap picks the adapter for
-- the current filetype (see lua/plugins/ide.lua). Languages that need a few
-- extra entries register them in `M.ft_extras` below.
--
-- Every mapping requires its module inside the callback rather than at
-- registration time, so defining the menus never forces neotest/dap to load.

local map = vim.keymap.set

local M = {}

-- Open a bottom terminal split running `argv`, optionally naming the buffer.
-- Shared by the per-filetype extras.
function M.term_run(argv, name)
  vim.cmd("botright split | resize 15")
  vim.cmd("terminal")
  local chan = vim.b.terminal_job_id
  if chan then
    local line = (type(argv) == "table") and table.concat(argv, " ") or argv
    vim.fn.chansend(chan, line .. "\n")
  end
  if name then
    vim.api.nvim_buf_set_name(0, name)
  end
  vim.cmd("startinsert")
end

-- ==== Testing <leader>t ==== --
local function setup_test_maps()
  map("n", "<leader>tn", function()
    require("neotest").run.run()
  end, { desc = "🧭 Test Run: Nearest" })

  map("n", "<leader>tf", function()
    require("neotest").run.run(vim.fn.expand("%"))
  end, { desc = "📄 Test Run: File" })

  map("n", "<leader>tp", function()
    require("neotest").run.run(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h"))
  end, { desc = "📦 Test Run: Directory" })

  map("n", "<leader>ta", function()
    require("neotest").run.run({ suite = true })
  end, { desc = "🧮 Test Run: All (suite)" })

  map("n", "<leader>tl", function()
    require("neotest").run.run_last()
  end, { desc = "📍 Test Run: Last" })

  map("n", "<leader>tv", function()
    -- jest/vitest read `-v` as --version, so they need their own spelling
    local verbose = { "-v" }
    if vim.bo.filetype:match("^javascript") or vim.bo.filetype:match("^typescript") then
      local root = vim.fs.root(0, "package.json") or vim.uv.cwd()
      verbose = vim.uv.fs_stat(root .. "/node_modules/.bin/vitest") and { "--reporter=verbose" } or { "--verbose" }
    end
    require("neotest").run.run({ suite = false, strategy = "integrated", args = verbose })
  end, { desc = "📃 Test Run: Nearest (verbose)" })

  map("n", "<leader>tS", function()
    require("neotest").run.stop()
  end, { desc = "🛑 Test: Stop" })

  map("n", "<leader>tw", function()
    require("neotest").watch.toggle(vim.fn.expand("%"))
  end, { desc = "👀 Watch: Toggle (file)" })

  map("n", "<leader>to", function()
    require("neotest").output.open({ enter = false, short = true })
  end, { desc = "🖥️ Output: Last" })

  map("n", "<leader>tO", function()
    require("neotest").output_panel.toggle()
  end, { desc = "📜 Output Panel: Toggle" })

  map("n", "<leader>ts", function()
    require("neotest").summary.toggle()
  end, { desc = "📝 Summary: Toggle" })

  map("n", "<leader>td", function()
    require("neotest").run.run({ strategy = "dap", suite = false })
  end, { desc = "🐞 Debug: Nearest Test" })
end

-- ==== Debugging <leader>d ==== --
local function setup_debug_maps()
  -- Breakpoints --
  map("n", "<leader>db", function()
    require("dap").toggle_breakpoint()
  end, { desc = "⛔️ Breakpoint: Toggle" })

  map("n", "<leader>dB", function()
    vim.ui.input({ prompt = "Breakpoint condition: " }, function(cond)
      if cond and #cond > 0 then
        require("dap").set_breakpoint(cond)
      end
    end)
  end, { desc = "⚙️ Breakpoint: Conditional" })

  map("n", "<leader>dC", function()
    require("dap").clear_breakpoints()
  end, { desc = "🧹 Breakpoint: Clear All" })

  -- Controls --
  map("n", "<leader>dc", function()
    require("dap").continue()
  end, { desc = "▶️ Start/Continue" })

  map("n", "<leader>di", function()
    require("dap").step_into()
  end, { desc = "⤵️ Step Into" })

  map("n", "<leader>do", function()
    require("dap").step_over()
  end, { desc = "⏭️ Step Over" })

  map("n", "<leader>dO", function()
    require("dap").step_out()
  end, { desc = "⤴️ Step Out" })

  map("n", "<leader>dr", function()
    require("dap").restart()
  end, { desc = "🔁 Restart" })

  map("n", "<leader>dL", function()
    require("dap").run_last()
  end, { desc = "📍 Run Last Configuration" })

  map("n", "<leader>dS", function()
    require("dap").terminate()
  end, { desc = "🛑 Stop" })

  -- UI/Introspection --
  map("n", "<leader>du", function()
    require("dapui").toggle()
  end, { desc = "💻 DAP UI: Toggle" })

  map("n", "<leader>ds", function()
    require("dapui").open({})
  end, { desc = "👓 View: Scopes/Stacks/Breakpoints" })

  map("n", "<leader>dv", function()
    require("dap.ui.widgets").hover()
  end, { desc = "🔬 Inspect Variable (hover)" })

  map("n", "<leader>dR", function()
    require("dap").repl.toggle()
  end, { desc = "💬 REPL: Toggle" })
end

-- ==== Per-filetype extras ==== --
-- filetype -> function(buf): buffer-local maps layered on top of the universal
-- menus. To support a new language, add one entry here (and its neotest
-- adapter in lua/plugins/test.lua).
M.ft_extras = {
  go = function(buf)
    local function run_all_with_coverage()
      vim.ui.input({ prompt = "Build tags (optional, space/comma-separated): " }, function(input)
        local tags = (input and input:match("%S")) and (input:gsub(",", " "):gsub("%s+", " ")) or nil

        local argv = { "go", "test", "./...", "-cover", "-count=1", "-coverprofile=coverage.out" }
        if tags then
          table.insert(argv, "-tags")
          table.insert(argv, tags)
        end

        M.term_run(argv, "go test (coverage)")
      end)
    end

    map("n", "<leader>tA", run_all_with_coverage, {
      desc = "🔦 Go Test Run: All (coverage, optional -tags)",
      buffer = buf,
    })

    map("n", "<leader>tC", function()
      M.term_run({ "go", "tool", "cover", "-func=coverage.out" }, "go coverage summary")
    end, { desc = "📊 Coverage: Summary (coverage.out)", buffer = buf })

    map("n", "<leader>tH", function()
      vim.fn.jobstart({ "go", "tool", "cover", "-html=coverage.out" }, { detach = true })
    end, { desc = "🖼️ Coverage: HTML (browser)", buffer = buf })

    map("n", "<leader>tu", function()
      local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":h")
      M.term_run({ "go", "test", dir, "-count=1", "-update" }, "go test (pkg -update)")
    end, { desc = "📦 Go Test: Package (-update snapshots)", buffer = buf })
  end,

  python = function(buf)
    local py = require("util.python")

    local function run(argv, name)
      local root = py.project_root(vim.api.nvim_buf_get_name(buf))
      M.term_run("cd " .. vim.fn.shellescape(root) .. " && " .. table.concat(argv, " "), name)
    end

    map("n", "<leader>tA", function()
      vim.ui.input({ prompt = "Markers (optional, -m expression): " }, function(input)
        local argv = { py.python(), "-m", "pytest", "--cov", "--cov-report=term-missing" }
        if input and input:match("%S") then
          table.insert(argv, "-m")
          table.insert(argv, vim.fn.shellescape(input))
        end
        run(argv, "pytest (coverage)")
      end)
    end, { desc = "🔦 Python Test Run: All (coverage, optional -m)", buffer = buf })

    map("n", "<leader>tC", function()
      run({ py.python(), "-m", "coverage", "report", "-m" }, "python coverage summary")
    end, { desc = "📊 Coverage: Summary (.coverage)", buffer = buf })

    map("n", "<leader>tH", function()
      local root = py.project_root(vim.api.nvim_buf_get_name(buf))
      vim.system({ py.python(), "-m", "coverage", "html" }, { cwd = root }, function(out)
        vim.schedule(function()
          if out.code ~= 0 then
            vim.notify(out.stderr ~= "" and out.stderr or out.stdout, vim.log.levels.ERROR, { title = "coverage" })
            return
          end
          vim.ui.open(root .. "/htmlcov/index.html")
        end)
      end)
    end, { desc = "🖼️ Coverage: HTML (browser)", buffer = buf })

    map("n", "<leader>tu", function()
      local file = vim.api.nvim_buf_get_name(buf)
      run({ py.python(), "-m", "pytest", vim.fn.shellescape(file), "--snapshot-update" }, "pytest (-snapshot-update)")
    end, { desc = "📸 Python Test: File (--snapshot-update)", buffer = buf })
  end,
}

local function js_extras(buf)
  local function package_root()
    return vim.fs.root(vim.api.nvim_buf_get_name(buf), "package.json") or vim.uv.cwd()
  end

  local function runner(root)
    if vim.uv.fs_stat(root .. "/node_modules/.bin/vitest") then
      return "vitest"
    end
    return "jest"
  end

  local function run(args, name)
    local root = package_root()
    local tool = runner(root)
    local argv = { "npx", tool }
    if tool == "vitest" then
      table.insert(argv, "run")
    end
    vim.list_extend(argv, args[tool])
    M.term_run("cd " .. vim.fn.shellescape(root) .. " && " .. table.concat(argv, " "), name)
  end

  map("n", "<leader>tA", function()
    run({ vitest = { "--coverage" }, jest = { "--coverage" } }, "js test (coverage)")
  end, { desc = "🔦 JS Test Run: All (coverage)", buffer = buf })

  map("n", "<leader>tC", function()
    run({
      vitest = { "--coverage", "--coverage.reporter=text-summary" },
      jest = { "--coverage", "--coverageReporters=text-summary" },
    }, "js coverage summary")
  end, { desc = "📊 Coverage: Summary (re-runs suite)", buffer = buf })

  map("n", "<leader>tH", function()
    local root = package_root()
    for _, rel in ipairs({ "/coverage/index.html", "/coverage/lcov-report/index.html" }) do
      if vim.uv.fs_stat(root .. rel) then
        return vim.ui.open(root .. rel)
      end
    end
    vim.notify("No HTML coverage report; run <leader>tA first", vim.log.levels.WARN, { title = "coverage" })
  end, { desc = "🖼️ Coverage: HTML (browser)", buffer = buf })

  map("n", "<leader>tu", function()
    local file = vim.fn.shellescape(vim.api.nvim_buf_get_name(buf))
    run({ vitest = { file, "-u" }, jest = { file, "-u" } }, "js test (-u snapshots)")
  end, { desc = "📸 JS Test: File (-u snapshots)", buffer = buf })
end

for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
  M.ft_extras[ft] = js_extras
end

function M.setup()
  setup_test_maps()
  setup_debug_maps()

  local wkok, wk = pcall(require, "which-key")
  if wkok then
    wk.add({
      { "<leader>t", group = "test" },
      { "<leader>d", group = "debug" },
    })
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    group = vim.api.nvim_create_augroup("config_testing_ft_extras", { clear = true }),
    callback = function(ev)
      local extras = M.ft_extras[vim.bo[ev.buf].filetype]
      if extras then
        extras(ev.buf)
      end
    end,
  })
end

return M
