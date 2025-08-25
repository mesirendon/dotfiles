local map = vim.keymap.set
local silent = { silent = true }

-- Splits with arrows
map("n", "<Up>",    "<C-w>k", silent)
map("n", "<Down>",  "<C-w>j", silent)
map("n", "<Left>",  "<C-w>h", silent)
map("n", "<Right>", "<C-w>l", silent)

-- Tabs
map("n", "<C-Left>",  ":tabprevious<CR>", silent)
map("n", "<C-Right>", ":tabnext<CR>",     silent)
map("n", "<A-Left>",  function()
  vim.cmd("silent! execute 'tabmove ' .. (tabpagenr()-2)")
end, silent)
map("n", "<A-Right>", function()
  vim.cmd("silent! execute 'tabmove ' .. (tabpagenr()+1)")
end, silent)

-- qq -> write & close current buffer (similar to :w|bd)
map("n", "qq", ":w|bd<CR>", silent)

-- F3 / F4 toggles (NERDTree/Taglist analogs)
map("n", "<F3>", ":NvimTreeToggle<CR>", silent)   -- file explorer
map("n", "<F4>", ":AerialToggle! right<CR>", silent) -- taglist-like outline

-- EasyMotion replacement: Leap
map({ "n", "x", "o" }, "s", "<Plug>(leap-forward-to)")
map({ "n", "x", "o" }, "S", "<Plug>(leap-backward-to)")
