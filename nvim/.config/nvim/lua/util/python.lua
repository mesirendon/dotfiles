local M = {}

local venv_dirs = { ".venv", "venv" }

---@param path? string file or directory to search upwards from (default: current buffer)
---@return string? venv directory, if one was found
function M.venv(path)
  if vim.env.VIRTUAL_ENV then
    return vim.env.VIRTUAL_ENV
  end
  path = path or vim.api.nvim_buf_get_name(0)
  if path == "" then
    path = vim.uv.cwd()
  end
  local root = vim.fs.root(path, function(name, dir)
    return vim.tbl_contains(venv_dirs, name) and vim.uv.fs_stat(dir .. "/" .. name .. "/bin/python") ~= nil
  end)
  if not root then
    return nil
  end
  for _, name in ipairs(venv_dirs) do
    local dir = root .. "/" .. name
    if vim.uv.fs_stat(dir .. "/bin/python") then
      return dir
    end
  end
end

---@param path? string
---@return string python executable
function M.python(path)
  local venv = M.venv(path)
  return venv and (venv .. "/bin/python") or vim.fn.exepath("python3")
end

---@param path? string
---@return string
function M.project_root(path)
  path = path or vim.api.nvim_buf_get_name(0)
  return vim.fs.root(path, { "pyproject.toml", "setup.cfg", "setup.py", "pytest.ini", "tox.ini" }) or vim.uv.cwd()
end

return M
