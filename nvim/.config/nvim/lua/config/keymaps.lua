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

    -- ==== Testing <localleader>t ==== --
    map("n", "<localleader>tA", function()
      nt.run.run({ suite = true })
    end, { desc = "🧮 Go Test Run: All (suite)", buffer = buf })

    map("n", "<localleader>tp", function()
      nt.run.run((vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":h")))
    end, { desc = "📦 Go Test Run: Package (dir)", buffer = buf })

    map("n", "<localleader>tF", function()
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
