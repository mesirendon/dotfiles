-- Monorepo-aware projects for the Snacks `projects` picker.
--
-- The stock finder maps every recent file to its `.git` root, so a monorepo
-- collapses into a single project. Here each recent file is resolved to its
-- nearest module marker instead (the same markers `vim.g.root_spec` prefers),
-- so `go/transactions` and `ts/mcdk` show up as separate projects next to the
-- repo root. `modules()` lists every module inside the current repo, for
-- switching between them without going through the dashboard.

---@class util.projects
local M = {}

-- Sub-project markers. Kept in sync with the first entry of `vim.g.root_spec`
-- (see config/options.lua); override with `vim.g.project_markers`.
M.markers = vim.g.project_markers
  or {
    "go.mod",
    "go.work",
    "package.json",
    "deno.json",
    "Cargo.toml",
    "pyproject.toml",
  }

--- Nearest directory above `path` that holds a module marker.
---@param path string file or directory
---@return string?
function M.module_root(path)
  local dir = vim.fs.dirname(path)
  if not dir then
    return nil
  end
  local marker = vim.fs.find(M.markers, { path = dir, upward = true, type = "file" })[1]
  return marker and vim.fs.dirname(marker) or nil
end

--- Finder for the `projects` source: module roots of recent files, plus
--- everything the stock finder returns (git roots, `dev` dirs, `projects`).
---@param opts snacks.picker.projects.Config
---@type snacks.picker.finder
function M.finder(opts, ctx)
  local base = require("snacks.picker.source.recent").projects(opts, ctx)
  ---@async
  ---@param cb async fun(item: snacks.picker.finder.Item)
  return function(cb)
    local seen = {} ---@type table<string, boolean>
    local function add(dir)
      if dir and not seen[dir] and ctx.filter:match({ file = dir, text = dir }) then
        seen[dir] = true
        cb({ file = dir, text = dir, dir = true })
      end
    end

    if opts.recent ~= false then
      for _, file in ipairs(vim.v.oldfiles) do
        file = vim.fs.normalize(file)
        if (vim.uv or vim.loop).fs_stat(file) then
          add(M.module_root(file))
        end
      end
    end

    base(function(item)
      add(item.file)
    end)
  end
end

--- Pick a module inside the current repo and `:tcd` into it.
--- Unlike the projects picker this doesn't touch sessions: it only rescopes
--- the current tab page, so pickers/terminals/lazygit follow the module.
---@param opts? snacks.picker.projects.Config
function M.modules(opts)
  local root = require("util").root.git()
  Snacks.picker.projects(vim.tbl_deep_extend("force", {
    title = "Modules",
    dev = { root },
    projects = { root },
    patterns = M.markers,
    recent = false,
    max_depth = 4,
    confirm = { "tcd", "picker_files" },
  }, opts or {}))
end

return M
