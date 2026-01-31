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

      vim.g["plantuml_previewer#plantuml_jar_path"] = "/opt/homebrew/Cellar/plantuml/1.2026.1/libexec/plantuml.jar"
    end,
  },
}
