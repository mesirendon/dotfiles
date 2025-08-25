local o, wo, bo = vim.o, vim.wo, vim.bo

-- UI / basics
o.termguicolors = true         -- better colors
wo.number = true               -- line numbers
o.laststatus = 3               -- global statusline
o.cmdheight = 3                -- like your wide cmdline
o.ruler = true
o.hidden = true                -- keep buffers around
o.swapfile = false
o.fileformats = "unix"

-- List chars (tabs/trailing)
o.list = true
o.listchars = "tab:| ,trail:.,nbsp:."

-- Search
o.hlsearch = true
o.incsearch = true

-- Indent / tabs
bo.expandtab = true
bo.tabstop = 2
bo.shiftwidth = 2
o.smartindent = true
o.autoindent = true

-- Grep program: ripgrep if available, else fallback
if vim.fn.executable("rg") == 1 then
  o.grepprg = "rg --vimgrep"
  o.grepformat = "%f:%l:%c:%m"
end

-- Light theme preference (we’ll set colors via plugin)
vim.opt.background = "light"
