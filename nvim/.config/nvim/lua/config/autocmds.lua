-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function smart_update(buf)
  local bo = vim.bo[buf]
  -- only normal file buffers, not help/term/quickfix, etc.
  if bo.buftype ~= "" or bo.readonly or not bo.modifiable then
    return
  end
  if bo.modified then
    -- write without noise; 'update' writes only when needed
    pcall(function()
      vim.cmd("silent! keepalt keepjumps update")
    end)
  end
end

vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "FocusLost" }, {
  callback = function(args)
    smart_update(args.buf)
  end,
  desc = "Auto-save when leaving buffer/window or losing focus",
})
