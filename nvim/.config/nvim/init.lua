-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.opt.guicursor = {
  "n-v-c:block", -- Normal, Visual, Command mode: block cursor
  "i-ci-ve:ver25", -- Insert, Command-line insert: vertical bar
  "r-cr:hor20", -- Replace modes: horizontal underline
  "o:hor50", -- Operator-pending: thicker underline
}
