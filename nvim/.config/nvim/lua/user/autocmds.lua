local group = vim.api.nvim_create_augroup("UserAutoCmds", { clear = true })

-- Open NvimTree when starting without a file like VimEnter NERDTree
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    if vim.fn.argc() == 0 then
      require("nvim-tree.api").tree.open()
    end
  end,
})
