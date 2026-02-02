local function file_exists(p)
  return p and vim.uv.fs_stat(p) ~= nil
end
local function get_plantuml_jar()
  -- Using brew prefix (works for Homebrew + Linuxbrew)
  if vim.fn.executable("brew") == 1 then
    local prefix = vim.fn.system({ "brew", "--prefix", "plantuml" }):gsub("%s+$", "")
    if prefix ~= "" then
      local jar = prefix .. "/libexec/plantuml.jar"
      if file_exists(jar) then
        return jar
      end
    end
  end
end

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

      local jar = get_plantuml_jar()
      if jar then
        vim.g["plantuml_previewer#plantuml_jar_path"] = jar
      end
    end,
  },
}
