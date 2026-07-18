-- Snacks core loader. Other files (ui.lua, editor.lua, dashboard.lua) extend
-- this same spec with more opts; lazy.nvim merges them by plugin name.
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      picker = {
        win = {
          input = {
            keys = {
              ["<a-c>"] = { "toggle_cwd", mode = { "n", "i" } },
            },
          },
        },
        actions = {
          toggle_cwd = function(p)
            local root = require("util").root({ buf = p.input.filter.current_buf, normalize = true })
            local cwd = vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
            local current = p:cwd()
            p:set_cwd(current == root and cwd or root)
            p:find()
          end,
        },
      },
      explorer = {},
    },
    config = function(_, opts)
      local notify = vim.notify
      require("snacks").setup(opts)
      -- restore vim.notify after snacks setup and let noice.nvim take over,
      -- so early notifications still show up in noice history
      if require("util").has("noice.nvim") then
        vim.notify = notify
      end
    end,
  },
}
