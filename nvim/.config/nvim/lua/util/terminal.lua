-- Terminal helpers on top of toggleterm.nvim. `root = true` (default) resolves
-- the nearest project via `util.root` (which, with the current `root_spec`,
-- means the enclosing module in a monorepo), `root = false` uses Neovim's cwd.
-- The keymaps in `plugins/toggleterm.lua` bind lowercase to cwd and uppercase
-- to the root dir.

---@class util.terminal
local M = {}

-- Terminals are cached by direction + dir so re-pressing a keymap toggles the
-- same shell instead of spawning a new one.
---@type table<string, table>
M.cache = {}

---@param root? boolean
---@return string
function M.dir(root)
  if root == false then
    return vim.fs.normalize(vim.uv.cwd() or ".")
  end
  return require("util").root()
end

---@param opts? { direction?: string, root?: boolean, cmd?: string|string[], count?: number }
function M.open(opts)
  opts = opts or {}
  local direction = opts.direction or "float"
  local dir = M.dir(opts.root)

  local key = direction .. ":" .. dir
  local term = M.cache[key]

  if not term or not vim.api.nvim_buf_is_valid(term.bufnr or -1) then
    term = require("toggleterm.terminal").Terminal:new({
      cmd = opts.cmd,
      dir = dir,
      direction = direction,
      count = opts.count,
      hidden = true,
      on_exit = function()
        M.cache[key] = nil
      end,
    })
    M.cache[key] = term
  end

  term:toggle()
end

-- Fresh terminal, never reused: always gets its own `count`.
---@param opts? { direction?: string, root?: boolean }
function M.new(opts)
  opts = opts or {}
  require("toggleterm.terminal").Terminal
    :new({
      dir = M.dir(opts.root),
      direction = opts.direction or "float",
      hidden = true,
    })
    :toggle()
end

---@type table<string, table>
M.lazygits = {}

---@param opts? { root?: boolean }
function M.lazygit(opts)
  opts = opts or {}

  if vim.fn.executable("lazygit") ~= 1 then
    require("util").error("`lazygit` not found in $PATH — install it with `brew install lazygit`")
    return
  end

  local dir = opts.root == false and vim.fs.normalize(vim.uv.cwd() or ".") or require("util").root.git()
  local term = M.lazygits[dir]

  if not term or not vim.api.nvim_buf_is_valid(term.bufnr or -1) then
    term = require("toggleterm.terminal").Terminal:new({
      cmd = "lazygit",
      dir = dir,
      direction = "float",
      hidden = true,
      close_on_exit = true,
      on_open = function(t)
        -- let lazygit handle <esc>/q itself instead of the toggleterm maps
        pcall(vim.keymap.del, "t", "<esc>", { buffer = t.bufnr })
        pcall(vim.keymap.del, "n", "q", { buffer = t.bufnr })
      end,
      on_exit = function()
        M.lazygits[dir] = nil
      end,
    })
    M.lazygits[dir] = term
  end

  term:toggle()
end

return M
