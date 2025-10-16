return {
  "catgoose/nvim-colorizer.lua",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("colorizer").setup({
      filetypes = {
        "css",
        "scss",
        "sass",
        "html",
        "javascript",
        "typescript",
        "lua",
      },
      user_default_options = {
        RGB = true, -- #RGB
        RRGGBB = true, -- #RRGGBB
        names = true, -- "blue", "red", etc.
        RRGGBBAA = true, -- #RRGGBBAA
        rgb_fn = true, -- rgb(), rgba()
        hsl_fn = true, -- hsl(), hsla()
        mode = "background", -- highlight style: background|foreground|virtualtext
        tailwind = true, -- highlight Tailwind colors
      },
    })
  end,
}
