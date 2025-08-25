return {
  -- Colorschemes
  { "folke/tokyonight.nvim", lazy = false, priority = 1000,
    opts = { style = "day", light_style = "day", transparent = false },
    config = function(_, opts) require("tokyonight").setup(opts); vim.cmd.colorscheme("tokyonight") end
  },
  -- Try solarized/monokai later if I get eye exhaustion:
  -- { "ishan9299/nvim-solarized-lua", lazy = true },
  -- { "loctvl842/monokai-pro.nvim", lazy = true, opts = { filter = "pro" } },

  -- File explorer (NERDTree replacement)
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { view = { width = 34 }, renderer = { group_empty = true }, git = { enable = true } } },

  -- Taglist-like symbols/outline
  { "stevearc/aerial.nvim", opts = { layout = { default_direction = "right" } } },

  -- EasyMotion replacement
  { "ggandor/leap.nvim",
    config = function() require("leap").add_default_mappings() end },

  -- Statusline
  { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { options = { theme = "auto", section_separators = "", component_separators = "│" } } },

  -- Git signs
  { "lewis6991/gitsigns.nvim", opts = {} },

  -- Comments & surround
  { "numToStr/Comment.nvim", opts = {} },
  { "kylechui/nvim-surround", version = "*", opts = {} },

  -- Telescope (fuzzy find) + ripgrep/fd | already installed
  { "nvim-lua/plenary.nvim" },
  { "nvim-telescope/telescope.nvim", tag = "0.1.6", opts = {} },

  -- Treesitter (better syntax highlighting/selection)
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate",
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      ensure_installed = { "go", "gomod", "gowork", "bash", "lua", "html", "css", "javascript", "typescript", "json", "yaml", "toml", "markdown" },
    } },
}

-- LSP & tooling
{ "williamboman/mason.nvim", build = ":MasonUpdate", opts = {} },
{ "williamboman/mason-lspconfig.nvim", opts = {} },
{ "neovim/nvim-lspconfig" },
{ "j-hui/fidget.nvim", opts = {}, tag = "legacy" }, -- tiny LSP status

-- Format on save
{ "stevearc/conform.nvim", opts = {} },

-- none-ls (diagnostics/formatters via CLI tools)
{ "nvimtools/none-ls.nvim" },
{ "jay-babu/mason-null-ls.nvim", opts = {} },

-- Completion (minimal)
{ "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
  },
},
