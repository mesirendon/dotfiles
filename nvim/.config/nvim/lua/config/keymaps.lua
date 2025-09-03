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
