-- Go first IDE setup + common languages
return {
  -- 1) Making sure dev tools are installed
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_extend("force", opts.ensure_installed or {}, {
        -- Go
        "gopls",
        "gofumpt",
        "goimports",
        "golangci-lint",
        "delve",
        -- TS/JS
        "vtsls",
        "prettierd",
        "eslint_d",
        -- Lua
        "lua-language-server",
        "stylua",
        -- Bash / Shell
        "bash-language-server",
        "shfmt",
        "shellcheck",
      })
    end,
  },
  -- 2) LSP Servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              analyses = { unusedparams = true, shadow = true },
              staticcheck = true,
            },
          },
        },
        vtsls = {},
        bashls = {},
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false },
            },
          },
        },
      },
    },
  },
  -- 3) Formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "gofumpt", "goimports" },
        lua = { "stylua" },
        javascript = { "prettierd", "prettier" },
        typescript = { "prettierd", "prettier" },
        json = { "prettierd", "prettier" },
        yaml = { "prettierd", "prettier" },
        html = { "prettierd", "prettier" },
        css = { "prettierd", "prettier" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
      },
    },
  },
  -- 4) Linting
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        go = { "golangcilint" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        zsh = { "shellcheck" },
      },
    },
  },
  -- 5) Debugging for Go
  { "mfussenegger/nvim-dap" },
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    config = function()
      require("dap-go").setup()
    end,
  },
}
