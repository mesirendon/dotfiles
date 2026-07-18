-- GitUI terminal integration (ported from LazyVim's util.gitui extra).
-- Owns <leader>gg / <leader>gG (instead of lazygit).
return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "gitui" } },
    keys = {
      {
        "<leader>gG",
        function()
          Snacks.terminal({ "gitui" })
        end,
        desc = "GitUi (cwd)",
      },
      {
        "<leader>gg",
        function()
          Snacks.terminal({ "gitui" }, { cwd = require("util").root.git() })
        end,
        desc = "GitUi (Root Dir)",
      },
    },
  },
}
