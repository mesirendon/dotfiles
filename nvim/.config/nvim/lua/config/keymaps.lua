-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local opts = { silent = true, noremap = true }

-- Quick theme toggling
map("n", "<leader>td", "<cmd>ThemeDay<cr>", { desc = "Theme: Day" })
map("n", "<leader>tn", "<cmd>ThemeNight<cr>", { desc = "Theme: Night" })

map("n", "+", "<C-a>", opts)
map("n", "-", "<C-x>", opts)

-- Go
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gomod",
  callback = function(ev)
    local buf = ev.buf
    local wkok, wk = pcall(require, "which-key")
    if wkok then
      wk.add({
        { "<localleader>g", group = "Go Mod", buffer = buf },
      })
    end
    map("n", "<localleader>gg", function()
      vim.cmd("split | terminal go get -u ./...")
      vim.cmd("startinsert")
    end, { desc = "⬇️ Go Mod: Update Packages", buffer = buf })

    map("n", "<localleader>gt", function()
      vim.cmd("split | terminal go mod tidy")
      vim.cmd("startinsert")
    end, { desc = "🧹 Go Mod: Tidy", buffer = buf })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function(ev)
    local buf = ev.buf
    local nt = require("neotest")
    local dap = require("dap")
    local dapui = require("dapui")
    local wkok, wk = pcall(require, "which-key")
    if wkok then
      wk.add({
        { "<localleader>t", group = "Tests", buffer = buf },
        { "<localleader>d", group = "Debug", buffer = buf },
      })
    end

    local function term_run(argv, name)
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

    local function run_all_with_coverage()
      vim.ui.input({ prompt = "Build tags (optional, space/comma-separated): " }, function(input)
        local tags = (input and input:match("%S")) and (input:gsub(",", " "):gsub("%s+", " ")) or nil

        local argv = { "go", "test", "./...", "-cover", "-count=1", "-coverprofile=coverage.out" }
        if tags then
          table.insert(argv, "-tags")
          table.insert(argv, tags)
        end

        term_run(argv, "go test (coverage)")
      end)
    end

    -- ==== Testing <localleader>t ==== --
    map(
      "n",
      "<localleader>tA",
      run_all_with_coverage,
      { desc = "🔦 Go Test Run: All (coverage, optional -tags)", buffer = buf }
    )

    map("n", "<localleader>tC", function()
      term_run({ "go", "tool", "cover", "-func=coverage.out" }, "go coverage summary")
    end, { desc = "📊 Coverage: Summary (coverage.out)", buffer = buf })

    map("n", "<localleader>tH", function()
      vim.fn.jobstart({ "go", "tool", "cover", "-html=coverage.out" }, { detach = true })
    end, { desc = "🖼️ Coverage: HTML (browser)", buffer = buf })

    map("n", "<localleader>ta", function()
      nt.run.run({ suite = true })
    end, { desc = "🧮 Go Test Run: All (suite)", buffer = buf })

    map("n", "<localleader>tp", function()
      nt.run.run((vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":h")))
    end, { desc = "📦 Go Test Run: Package (dir)", buffer = buf })

    map("n", "<localleader>tf", function()
      nt.run.run(vim.fn.expand("%"))
    end, { desc = "📄 Go Test Run: File", buffer = buf })

    map("n", "<localleader>tn", function()
      nt.run.run()
    end, { desc = "🧭 Go Test Run: Nearest (subtest)", buffer = buf })

    map("n", "<localleader>tl", function()
      nt.run.run_last()
    end, { desc = "📍 Go Test Run: Last", buffer = buf })

    map("n", "<localleader>to", function()
      nt.output.open({ enter = false, short = true })
    end, { desc = "🖥️ Output: Last", buffer = buf })

    map("n", "<localleader>ts", function()
      nt.summary.toggle()
    end, { desc = "📝 Summary: Toggle", buffer = buf })

    map("n", "<localleader>td", function()
      nt.run.run({ strategy = "dap", suite = false })
    end, { desc = "🐞 Debug: Nearest", buffer = buf })

    -- ==== Debugging <localleader>d ==== --
    -- Breakpoints --
    map("n", "<localleader>db", function()
      dap.toggle_breakpoint()
    end, { desc = "⛔️ Breakpoint: Toggle", buffer = buf })

    map("n", "<localleader?dB", function()
      vim.ui.input({ prompt = "Breakpoint condition: " }, function(cond)
        if cond and #cond > 0 then
          dap.set_breakpoint(cond)
        end
      end)
    end, { desc = "⚙️ Breakpoint: Conditional", buffer = buf })

    map("n", "<localleader>dC", function()
      dap.clear_breakpoints()
    end, { desc = "🧹 Breakpoint: Clear All", buffer = buf })

    -- Controls --
    map("n", "<localleader>dc", function()
      dap.continue()
    end, { desc = "▶️ Start/Continue", buffer = buf })

    map("n", "<localleader>di", function()
      dap.step_into()
    end, { desc = "⤵️ Step Into", buffer = buf })

    map("n", "<localleader>do", function()
      dap.step_over()
    end, { desc = "⏭️ Step Over", buffer = buf })

    map("n", "<localleader>dO", function()
      dap.step_out()
    end, { desc = "⤴️ Step Out", buffer = buf })

    map("n", "<localleader>dr", function()
      dap.restart()
    end, { desc = "🔁 Restart", buffer = buf })

    map("n", "<localleader>dS", function()
      dap.terminate()
    end, { desc = "🛑 Stop", buffer = buf })

    -- UI/Introspection
    map("n", "<localleader>du", function()
      dapui.toggle()
    end, { desc = "💻 DAP UI: Toggle", buffer = buf })

    map("n", "<localleader>ds", function()
      dapui.open({})
    end, { desc = "👓 View: Scopes/Stacks/Breakpoints", buffer = buf })

    map("n", "<localleader>dv", function()
      require("dap.ui.widgets").hover()
    end, { desc = "🔬 Inspect Variable (hover)", buffer = buf })
  end,
})
