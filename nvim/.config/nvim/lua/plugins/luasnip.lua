return {
  "L3MON4D3/LuaSnip",
  lazy = true,
  dependencies = { "rafamadriz/friendly-snippets" },
  config = function()
    -- community snippets (blink uses LuaSnip as its snippet engine)
    require("luasnip.loaders.from_vscode").lazy_load()
    -- custom Lua snippets (e.g. Go templates in snippets/)
    require("luasnip.loaders.from_lua").lazy_load({
      paths = vim.fn.stdpath("config") .. "/lua/snippets",
    })
  end,
}
