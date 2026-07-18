-- Picker wrapper, ported from LazyVim's `util.pick`. Resolves the root dir and
-- opens Snacks.picker. Callable: `require("util.pick")("files")` returns a fn.

---@class util.pick
---@overload fun(command:string, opts?:table): fun()
local M = setmetatable({}, {
  __call = function(m, ...)
    return m.wrap(...)
  end,
})

-- Map generic command names to Snacks.picker sources.
M.commands = {
  files = "files",
  live_grep = "grep",
  oldfiles = "recent",
}

---@param command? string
---@param opts? table
function M.open(command, opts)
  command = command ~= "auto" and command or "files"
  opts = vim.deepcopy(opts or {})

  if type(opts.cwd) == "boolean" then
    opts.cwd = nil
  end

  if not opts.cwd and opts.root ~= false then
    opts.cwd = require("util").root({ buf = opts.buf })
  end
  opts.root = nil

  command = M.commands[command] or command
  Snacks.picker.pick(command, opts)
end

---@param command? string
---@param opts? table
function M.wrap(command, opts)
  opts = opts or {}
  return function()
    M.open(command, vim.deepcopy(opts))
  end
end

function M.config_files()
  return M.wrap("files", { cwd = vim.fn.stdpath("config") })
end

return M
