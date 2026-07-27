-- Bridges system luarocks into Neovim:
--   1. runtime  — append the luarocks trees to package.path/cpath so require() works
--   2. lua_ls   — expose the derived library dirs for completion/hover (see plugins/ide.lua)
--
-- Neovim is LuaJIT (Lua 5.1), so rocks must be built for 5.1 to load at runtime.
-- Install them with:  luarocks --lua-version 5.1 --local install <rock>
-- (scripts/luarocks.sh points luarocks at Neovim's LuaJIT so this "just works".)

local M = {}

-- Cached once per session by compute().
M.lua_path = nil ---@type string?  LUA_PATH additions (?.lua patterns)
M.lua_cpath = nil ---@type string?  LUA_CPATH additions (?.so patterns)
M.library = nil ---@type string[]?  directories for lua_ls Lua.workspace.library

---@param kind string one of "--lr-path" | "--lr-cpath"
---@return string
local function query(kind)
  local out = vim.fn.system({ "luarocks", "--lua-version", "5.1", "path", kind })
  if vim.v.shell_error ~= 0 then
    return ""
  end
  return vim.trim(out)
end

-- Turn a package.path-style pattern string into unique, existing base directories,
-- stripping the trailing `/?.lua`, `/?/init.lua`, `/?.so`, etc.
---@param patterns string
---@return string[]
local function dirs_from_patterns(patterns)
  local seen, dirs = {}, {}
  for entry in vim.gsplit(patterns, ";", { plain = true }) do
    if entry ~= "" then
      local dir = entry:gsub("[/\\]%?.*$", "")
      if dir ~= "" and not seen[dir] and vim.fn.isdirectory(dir) == 1 then
        seen[dir] = true
        dirs[#dirs + 1] = dir
      end
    end
  end
  return dirs
end

-- Shell out to luarocks once and cache the results.
function M.compute()
  if M.lua_path then
    return
  end
  if vim.fn.executable("luarocks") == 0 then
    M.lua_path, M.lua_cpath, M.library = "", "", {}
    return
  end
  M.lua_path = query("--lr-path")
  M.lua_cpath = query("--lr-cpath")
  M.library = dirs_from_patterns(M.lua_path)
end

-- Make luarocks-installed modules require()-able inside Neovim. Idempotent.
function M.setup_runtime()
  M.compute()
  if M.lua_path ~= "" and not package.path:find(M.lua_path, 1, true) then
    package.path = package.path .. ";" .. M.lua_path
  end
  if M.lua_cpath ~= "" and not package.cpath:find(M.lua_cpath, 1, true) then
    package.cpath = package.cpath .. ";" .. M.lua_cpath
  end
end

-- Directories for lua_ls Lua.workspace.library (completion/hover).
---@return string[]
function M.lua_ls_library()
  M.compute()
  return M.library
end

return M
