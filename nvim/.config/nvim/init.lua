-- options (incl. leader keys) must load before lazy.nvim sets up plugin keymaps
require("config.options")

-- bootstrap lazy.nvim and plugins
require("config.lazy")

-- Make luarocks-installed modules require()-able inside Neovim.
require("config.luarocks").setup_runtime()

vim.opt.guicursor = {
  "n-v-c:block", -- Normal, Visual, Command mode: block cursor
  "i-ci-ve:ver25", -- Insert, Command-line insert: vertical bar
  "r-cr:hor20", -- Replace modes: horizontal underline
  "o:hor50", -- Operator-pending: thicker underline
}
