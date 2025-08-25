local lspconfig = require("lspconfig")
local mason = require("mason")
local mason_lsp = require("mason-lspconfig")

mason.setup({})
mason_lsp.setup({
  ensure_installed = {
    "gopls",
    "bashls",
    "html",
    "cssls",
    "tsserver",
    "jsonls",
    "yamlls",
  },
})

-- nvim-cmp capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

-- Common on_attach: keymaps etc.
local on_attach = function(_, bufnr)
  local map = function(m, lhs, rhs) vim.keymap.set(m, lhs, rhs, { buffer = bufnr, silent = true }) end
  map("n", "gd", vim.lsp.buf.definition)
  map("n", "gr", vim.lsp.buf.references)
  map("n", "gi", vim.lsp.buf.implementation)
  map("n", "K",  vim.lsp.buf.hover)
  map("n", "<leader>rn", vim.lsp.buf.rename)
  map("n", "<leader>ca", vim.lsp.buf.code_action)
  map("n", "<leader>ds", require("telescope.builtin").lsp_document_symbols)
  map("n", "<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols)
end

-- Servers
mason_lsp.setup_handlers({
  function(server)
    lspconfig[server].setup({ on_attach = on_attach, capabilities = capabilities })
  end,

  -- gopls with opinionated Go formatting & analysis
  ["gopls"] = function()
    lspconfig.gopls.setup({
      on_attach = on_attach,
      capabilities = capabilities,
      settings = {
        gopls = {
          usePlaceholders = true,
          codelenses = { gc_details = true, generate = true, test = true, tidy = true, upgrade_dependency = true },
          hints = { assignVariableTypes = true, compositeLiteralFields = true, parameterNames = true, rangeVariableTypes = true },
          analyses = { unusedparams = true, fieldalignment = true, shadow = true, nilness = true },
          gofumpt = true,            -- <- stricter gofmt
          staticcheck = true,
          directoryFilters = { "-**/vendor" },
        },
      },
    })
  end,

  -- tsserver: basic, let prettier handle formatting
  ["tsserver"] = function()
    lspconfig.tsserver.setup({
      on_attach = on_attach,
      capabilities = capabilities,
    })
  end,
})

pcall(require, "user.cmp")
