-- FORMAT ON SAVE (Conform)
require("conform").setup({
  notify_on_error = false,
  format_on_save = function(buf)
    -- disable for big files
    local max = 1024 * 200 -- 200KB
    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
    if ok and stats and stats.size > max then return nil end
    return { timeout_ms = 1000, lsp_fallback = true }
  end,
  formatters_by_ft = {
    go = { "gofumpt" }, -- gopls also formats; gofumpt adds stricter style
    sh = { "shfmt" },
    bash = { "shfmt" },
    javascript = { "prettierd", "prettier" },
    typescript = { "prettierd", "prettier" },
    javascriptreact = { "prettierd", "prettier" },
    typescriptreact = { "prettierd", "prettier" },
    css = { "prettierd", "prettier" },
    html = { "prettierd", "prettier" },
    json = { "prettierd", "prettier" },
    yaml = { "prettierd", "prettier" },
    markdown = { "prettierd", "prettier" },
    lua = { "stylua" },
  },
})

-- NONE-LS (diagnostics via CLIs: golangci-lint, shellcheck, etc.)
local null = require("null-ls")
require("mason-null-ls").setup({
  ensure_installed = {
    "golangci-lint",
    "shellcheck",
    "shfmt",
    "prettierd",
    "stylua",
  },
  automatic_installation = true,
})

null.setup({
  sources = {
    -- Go lint
    null.builtins.diagnostics.golangci_lint.with({
      condition = function(utils) return utils.root_has_file({ ".golangci.yml", ".golangci.yaml" }) end,
    }),
    -- Bash lint
    null.builtins.diagnostics.shellcheck,
    -- (Formatting is handled by Conform)
  },
})
