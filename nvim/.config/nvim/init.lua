-- 1) Leader mapping
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- 2) Bootstrap lazy.vim plugin manager
local lazypath = vim.fn.stdpath("data") .. "lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 3) Load my configs
require("user.options")
require("user.keymaps")
require("user.autocmds")
require("lazy").setup(require("user.plugins"))
require("user.lsp")
require("user.format")
