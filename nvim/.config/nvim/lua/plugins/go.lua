return {
  {
    "ray-x/go.nvim",
    dependencies = {
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
    },
    ft = { "go", "gomod", "gosum", "gowork" },
    build = ':lua require("go.install").update_all_sync()',
    opts = {
      lsp_cfg = false, -- nvim-lspconfig owns gopls
      lsp_gofumpt = false, -- conform.nvim owns gofumpt
      lsp_on_attach = false, -- don't override LazyVim's on_attach
      dap_debug = false, -- nvim-dap-go owns the dap config
      lsp_inlay_hints = { enable = false }, -- gopls already handles inlay hints
      icons = false, -- don't override dap signs
      sign_priority = 0,
    },
  },
}
