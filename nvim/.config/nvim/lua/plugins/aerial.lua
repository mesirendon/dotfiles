-- Aerial symbol browser (ported from LazyVim's aerial extra).
-- ide.lua extends this with layout width opts; keymaps.lua uses next/prev.
return {
  {
    "stevearc/aerial.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = function()
      local icons = vim.deepcopy(require("config.icons").icons.kinds)
      -- lua uses `Package` for control structures like if/else/for
      icons.lua = { Package = icons.Control }

      local kf = require("config.icons").kind_filter
      local filter_kind = assert(vim.deepcopy(kf))
      filter_kind._ = filter_kind.default
      filter_kind.default = nil

      return {
        attach_mode = "global",
        backends = { "lsp", "treesitter", "markdown", "man" },
        show_guides = true,
        layout = {
          resize_to_content = false,
          win_opts = {
            winhl = "Normal:NormalFloat,FloatBorder:NormalFloat,SignColumn:SignColumnSB",
            signcolumn = "yes",
            statuscolumn = " ",
          },
        },
        icons = icons,
        filter_kind = filter_kind,
        guides = {
          mid_item = "├╴",
          last_item = "└╴",
          nested_top = "│ ",
          whitespace = "  ",
        },
      }
    end,
    keys = {
      { "<leader>cs", "<cmd>AerialToggle<cr>", desc = "Aerial (Symbols)" },
    },
  },

  -- lualine integration
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      if not vim.g.trouble_lualine then
        table.insert(opts.sections.lualine_c, {
          "aerial",
          sep = " ",
          sep_icon = "",
          depth = 5,
          dense = false,
          dense_sep = ".",
          colored = true,
        })
      end
    end,
  },
}
