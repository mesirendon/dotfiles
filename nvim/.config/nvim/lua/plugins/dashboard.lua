return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      preset = {
        pick = function(cmd, opts)
          return require("util.pick")(cmd, opts)()
        end,
        header = [[
                _                     _ _   _     
               | |                   (_) | | |    
   ___ ___   __| | ___  ___ _ __ ___  _| |_| |__  
  / __/ _ \ / _` |/ _ \/ __| '_ ` _ \| | __| '_ \ 
 | (_| (_) | (_| |  __/\__ \ | | | | | | |_| | | |
  \___\___/ \__,_|\___||___/_| |_| |_|_|\__|_| |_|
]],
        footer = { "Write. Build. Learn." },
        -- stylua: ignore
        ---@type snacks.dashboard.Item[]
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
      sections = vim.list_extend(vim.fn.filereadable(vim.fn.expand("~/.config/nvim/logo.png")) == 1 and {
        {
          section = "terminal",
          cmd = "chafa ~/.config/nvim/logo.png --size 56",
          height = 17,
          padding = 1,
        },
      } or {}, {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      }),
    },
  },
}
