-- Small utility module that replaces the handful of `LazyVim.*` helpers the
-- config relied on, now that the LazyVim distribution is gone. Submodules
-- (`util.root`, `util.pick`) are loaded lazily via the __index metamethod.

---@class Util
local M = {}

setmetatable(M, {
  __index = function(t, k)
    local ok, mod = pcall(require, "util." .. k)
    if ok then
      rawset(t, k, mod)
      return mod
    end
  end,
})

function M.is_win()
  return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

---@param path string
---@return string
function M.norm(path)
  if path:sub(1, 1) == "~" then
    local home = vim.uv.os_homedir()
    if home:sub(-1) == "/" then
      home = home:sub(1, -2)
    end
    path = home .. path:sub(2)
  end
  path = path:gsub("\\", "/"):gsub("/+", "/")
  return path:sub(-1) == "/" and path:sub(1, -2) or path
end

---@param name string
---@return boolean
function M.has(name)
  local Config = require("lazy.core.config")
  return Config.plugins[name] ~= nil
end

---@param fn fun()
function M.on_very_lazy(fn)
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      fn()
    end,
  })
end

-- Run `fn` after plugin `name` has loaded (or immediately if already loaded).
---@param name string
---@param fn fun(name:string)
function M.on_load(name, fn)
  local Config = require("lazy.core.config")
  if Config.plugins[name] and Config.plugins[name]._.loaded then
    fn(name)
  else
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyLoad",
      callback = function(event)
        if event.data == name then
          fn(name)
          return true
        end
      end,
    })
  end
end

function M.warn(msg, opts)
  opts = opts or {}
  vim.notify(
    type(msg) == "table" and table.concat(msg, "\n") or msg,
    vim.log.levels.WARN,
    { title = opts.title or "Config" }
  )
end

function M.error(msg, opts)
  opts = opts or {}
  vim.notify(
    type(msg) == "table" and table.concat(msg, "\n") or msg,
    vim.log.levels.ERROR,
    { title = opts.title or "Config" }
  )
end

function M.info(msg, opts)
  opts = opts or {}
  vim.notify(
    type(msg) == "table" and table.concat(msg, "\n") or msg,
    vim.log.levels.INFO,
    { title = opts.title or "Config" }
  )
end

return M
