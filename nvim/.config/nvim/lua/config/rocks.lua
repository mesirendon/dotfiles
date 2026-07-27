-- Reads the declarative luarocks manifest (~/.config/nvim/Rockfile) and exposes it to
-- lazydev so each rock's LuaCATS annotation stubs provide hover/completion docs.
-- The same file drives rock installation in scripts/luarocks.sh (bootstrap).

local M = {}

local function manifest_path()
  return vim.fn.stdpath("config") .. "/Rockfile"
end

-- Parse the manifest into { rock, repo?, words? } entries. Empty if unreadable.
---@return { rock: string, repo: string?, words: string[]? }[]
function M.entries()
  local path = manifest_path()
  local out = {}
  if vim.fn.filereadable(path) == 0 then
    return out
  end
  for _, line in ipairs(vim.fn.readfile(path)) do
    line = vim.trim(line)
    if line ~= "" and not line:match("^#") then
      local fields = vim.split(line, "%s+", { trimempty = true })
      local rock, repo, words = fields[1], fields[2], fields[3]
      if rock then
        out[#out + 1] = {
          rock = rock,
          repo = (repo and repo ~= "-") and repo or nil,
          words = (words and words ~= "-") and vim.split(words, ",", { trimempty = true }) or nil,
        }
      end
    end
  end
  return out
end

-- lazy plugin specs for the LuaCATS stub repos (deduped) so lazydev can resolve them.
---@return table[]
function M.plugins()
  local seen, specs = {}, {}
  for _, e in ipairs(M.entries()) do
    if e.repo and not seen[e.repo] then
      seen[e.repo] = true
      specs[#specs + 1] = { e.repo, lazy = true }
    end
  end
  return specs
end

-- lazydev library entries mapping each stub's `library/` dir to its trigger words.
---@return table[]
function M.lazydev_library()
  local lib = {}
  for _, e in ipairs(M.entries()) do
    if e.repo and e.words then
      local name = e.repo:match("([^/]+)$") -- "LuaCATS/luasocket" -> "luasocket"
      lib[#lib + 1] = { path = name .. "/library", words = e.words }
    end
  end
  return lib
end

return M
