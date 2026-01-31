return {
  { "aklt/plantuml-syntax", ft = { "plantuml" } },
  { "tyru/open-browser.vim", lazy = true },
  {
    "weirongxu/plantuml-previewer.vim",
    ft = { "plantuml" },
    dependencies = { "tyru/open-browser.vim" },
    init = function()
      vim.filetype.add({
        extension = {
          puml = "plantuml",
        },
      })
    end,
  },
}
