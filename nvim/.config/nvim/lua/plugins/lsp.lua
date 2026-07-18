-- LSP base spec. Servers are supplied by plugins/ide.lua (opts.servers);
-- the attach keymaps, capabilities and diagnostics live in config/lsp.lua.
return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason.nvim",
      { "mason-org/mason-lspconfig.nvim", config = function() end },
    },
    opts = {
      ---@type table<string, vim.lsp.Config|boolean>
      servers = {},
      inlay_hints = { enabled = true },
    },
    config = function(_, opts)
      local lsp = require("config.lsp")
      lsp.setup()

      -- default config applied to every server (capabilities from blink.cmp)
      vim.lsp.config("*", { capabilities = lsp.capabilities() })

      local ensure = {}
      for server, cfg in pairs(opts.servers) do
        local enabled = cfg ~= false and not (type(cfg) == "table" and cfg.enabled == false)
        if enabled then
          cfg = type(cfg) == "table" and cfg or {}
          vim.lsp.config(server, cfg)
          ensure[#ensure + 1] = server
        end
      end

      if require("util").has("mason-lspconfig.nvim") then
        require("mason-lspconfig").setup({
          ensure_installed = ensure,
          automatic_enable = true,
        })
      else
        for _, server in ipairs(ensure) do
          vim.lsp.enable(server)
        end
      end
    end,
  },
}
