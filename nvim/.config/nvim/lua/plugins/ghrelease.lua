return {
  "mesirendon/nvim-ghrelease",
  cmd = "GhRelease",
  keys = {
    { "<leader>gr", "<cmd>GhRelease<cr>", desc = "GitHub Release: create" },
  },
  opts = {
    keymaps = { create = false },
  },
}
