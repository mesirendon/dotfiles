-- Loaded on VeryLazy (see config/lazy.lua).
-- General keymaps ported from LazyVim defaults + snacks picker/explorer, plus
-- the custom keymaps for this config.

local map = vim.keymap.set
local opts = { silent = true, noremap = true }
local Pick = require("util.pick")
local root = require("util").root

-- Language-agnostic test (<leader>t) and debug (<leader>d) menus.
require("config.testing").setup()

-- ============================================================================
-- General (ported LazyVim defaults)
-- ============================================================================

-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Move Lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Delete Other Buffers" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })

-- Clear search on escape
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- Clear search, diff update and redraw
map(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / Clear hlsearch / Diff Update" }
)

-- saner n/N
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- keywordprg
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- better indenting
map("x", "<", "<gv")
map("x", ">", ">gv")

-- commenting
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- lazy / new file
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- location / quickfix list
map("n", "<leader>xl", function()
  local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Location List" })
map("n", "<leader>xq", function()
  local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })
map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- diagnostics
local diagnostic_goto = function(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- windows
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

-- tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- highlights under cursor
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", function()
  vim.treesitter.inspect_tree()
  vim.api.nvim_input("I")
end, { desc = "Inspect Tree" })

-- ============================================================================
-- Snacks-powered keymaps (picker, explorer, git, terminal, toggles)
-- ============================================================================

-- picker
map("n", "<leader>,", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })
map("n", "<leader>/", Pick("grep"), { desc = "Grep (Root Dir)" })
map("n", "<leader>:", function()
  Snacks.picker.command_history()
end, { desc = "Command History" })
map("n", "<leader><space>", Pick("files"), { desc = "Find Files (Root Dir)" })
map("n", "<leader>n", function()
  Snacks.picker.notifications()
end, { desc = "Notification History" })
-- find
map("n", "<leader>fb", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })
map("n", "<leader>fc", Pick.config_files(), { desc = "Find Config File" })
map("n", "<leader>ff", Pick("files"), { desc = "Find Files (Root Dir)" })
map("n", "<leader>fF", Pick("files", { root = false }), { desc = "Find Files (cwd)" })
map("n", "<leader>fg", function()
  Snacks.picker.git_files()
end, { desc = "Find Files (git-files)" })
map("n", "<leader>fr", Pick("oldfiles"), { desc = "Recent" })
map("n", "<leader>fR", function()
  Snacks.picker.recent({ filter = { cwd = true } })
end, { desc = "Recent (cwd)" })
map("n", "<leader>fp", function()
  Snacks.picker.projects()
end, { desc = "Projects" })
-- explorer
map("n", "<leader>fe", function()
  Snacks.explorer({ cwd = root() })
end, { desc = "Explorer (root dir)" })
map("n", "<leader>fE", function()
  Snacks.explorer()
end, { desc = "Explorer (cwd)" })
map("n", "<leader>e", "<leader>fe", { desc = "Explorer (root dir)", remap = true })
map("n", "<leader>E", "<leader>fE", { desc = "Explorer (cwd)", remap = true })
-- search
map("n", "<leader>sb", function()
  Snacks.picker.lines()
end, { desc = "Buffer Lines" })
map("n", "<leader>sB", function()
  Snacks.picker.grep_buffers()
end, { desc = "Grep Open Buffers" })
map("n", "<leader>sg", Pick("live_grep"), { desc = "Grep (Root Dir)" })
map("n", "<leader>sG", Pick("live_grep", { root = false }), { desc = "Grep (cwd)" })
map("n", "<leader>sp", function()
  Snacks.picker.lazy()
end, { desc = "Search for Plugin Spec" })
map({ "n", "x" }, "<leader>sw", Pick("grep_word"), { desc = "Word (Root Dir)" })
map({ "n", "x" }, "<leader>sW", Pick("grep_word", { root = false }), { desc = "Word (cwd)" })
map("n", '<leader>s"', function()
  Snacks.picker.registers()
end, { desc = "Registers" })
map("n", "<leader>s/", function()
  Snacks.picker.search_history()
end, { desc = "Search History" })
map("n", "<leader>sa", function()
  Snacks.picker.autocmds()
end, { desc = "Autocmds" })
map("n", "<leader>sc", function()
  Snacks.picker.command_history()
end, { desc = "Command History" })
map("n", "<leader>sC", function()
  Snacks.picker.commands()
end, { desc = "Commands" })
map("n", "<leader>sd", function()
  Snacks.picker.diagnostics()
end, { desc = "Diagnostics" })
map("n", "<leader>sD", function()
  Snacks.picker.diagnostics_buffer()
end, { desc = "Buffer Diagnostics" })
map("n", "<leader>sh", function()
  Snacks.picker.help()
end, { desc = "Help Pages" })
map("n", "<leader>sH", function()
  Snacks.picker.highlights()
end, { desc = "Highlights" })
map("n", "<leader>si", function()
  Snacks.picker.icons()
end, { desc = "Icons" })
map("n", "<leader>sj", function()
  Snacks.picker.jumps()
end, { desc = "Jumps" })
map("n", "<leader>sk", function()
  Snacks.picker.keymaps()
end, { desc = "Keymaps" })
map("n", "<leader>sl", function()
  Snacks.picker.loclist()
end, { desc = "Location List" })
map("n", "<leader>sM", function()
  Snacks.picker.man()
end, { desc = "Man Pages" })
map("n", "<leader>sm", function()
  Snacks.picker.marks()
end, { desc = "Marks" })
map("n", "<leader>sR", function()
  Snacks.picker.resume()
end, { desc = "Resume" })
map("n", "<leader>sq", function()
  Snacks.picker.qflist()
end, { desc = "Quickfix List" })
map("n", "<leader>su", function()
  Snacks.picker.undo()
end, { desc = "Undotree" })
map("n", "<leader>uC", function()
  Snacks.picker.colorschemes()
end, { desc = "Colorschemes" })

-- git
map("n", "<leader>gd", function()
  Snacks.picker.git_diff()
end, { desc = "Git Diff (hunks)" })
map("n", "<leader>gs", function()
  Snacks.picker.git_status()
end, { desc = "Git Status" })
map("n", "<leader>gS", function()
  Snacks.picker.git_stash()
end, { desc = "Git Stash" })
map("n", "<leader>gL", function()
  Snacks.picker.git_log()
end, { desc = "Git Log (cwd)" })
map("n", "<leader>gb", function()
  Snacks.picker.git_log_line()
end, { desc = "Git Blame Line" })
map("n", "<leader>gf", function()
  Snacks.picker.git_log_file()
end, { desc = "Git Current File History" })
map("n", "<leader>gl", function()
  Snacks.picker.git_log({ cwd = root.git() })
end, { desc = "Git Log" })
map({ "n", "x" }, "<leader>gB", function()
  Snacks.gitbrowse()
end, { desc = "Git Browse (open)" })
map({ "n", "x" }, "<leader>gY", function()
  Snacks.gitbrowse({
    open = function(url)
      vim.fn.setreg("+", url)
    end,
    notify = false,
  })
end, { desc = "Git Browse (copy)" })
-- <leader>gg / <leader>gG are owned by plugins/gitui.lua (GitUi terminal).

-- terminal
map("n", "<leader>fT", function()
  Snacks.terminal()
end, { desc = "Terminal (cwd)" })
map("n", "<leader>ft", function()
  Snacks.terminal(nil, { cwd = root() })
end, { desc = "Terminal (Root Dir)" })
map({ "n", "t" }, "<c-/>", function()
  Snacks.terminal.focus(nil, { cwd = root() })
end, { desc = "Terminal (Root Dir)" })

-- notifications / scratch
map("n", "<leader>un", function()
  Snacks.notifier.hide()
end, { desc = "Dismiss All Notifications" })
map("n", "<leader>.", function()
  Snacks.scratch()
end, { desc = "Toggle Scratch Buffer" })
map("n", "<leader>S", function()
  Snacks.scratch.select()
end, { desc = "Select Scratch Buffer" })

-- toggles
Snacks.toggle({
  name = "Auto Format (Global)",
  get = function()
    return vim.g.autoformat == nil or vim.g.autoformat
  end,
  set = function(state)
    vim.g.autoformat = state
  end,
}):map("<leader>uf")
Snacks.toggle({
  name = "Auto Format (Buffer)",
  get = function()
    local b = vim.b.autoformat
    if b == nil then
      return vim.g.autoformat == nil or vim.g.autoformat
    end
    return b
  end,
  set = function(state)
    vim.b.autoformat = state
  end,
}):map("<leader>uF")
Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle.line_number():map("<leader>ul")
Snacks.toggle
  .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" })
  :map("<leader>uc")
Snacks.toggle.treesitter():map("<leader>uT")
Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
Snacks.toggle.dim():map("<leader>uD")
Snacks.toggle.animate():map("<leader>ua")
Snacks.toggle.indent():map("<leader>ug")
Snacks.toggle.scroll():map("<leader>uS")
Snacks.toggle.zoom():map("<leader>wm"):map("<leader>uZ")
Snacks.toggle.zen():map("<leader>uz")
if vim.lsp.inlay_hint then
  Snacks.toggle.inlay_hints():map("<leader>uh")
end

-- ============================================================================
-- Custom keymaps
-- ============================================================================

map("n", "+", "<C-a>", opts)
map("n", "-", "<C-x>", opts)

-- Symbol navigation (function/class), via aerial.nvim (LSP + treesitter backends)
-- Aerial has no per-kind filter for next()/prev(), so both old ]f/[f (function)
-- and ]c/[c (class) motions map to the same generic symbol jump.
local function aerial_next()
  require("aerial").next()
end
local function aerial_prev()
  require("aerial").prev()
end
map("n", "]f", aerial_next, { desc = "Next Symbol (function/class)" })
map("n", "[f", aerial_prev, { desc = "Prev Symbol (function/class)" })
map("n", "]c", aerial_next, { desc = "Next Symbol (function/class)" })
map("n", "[c", aerial_prev, { desc = "Prev Symbol (function/class)" })

-- Incremental selection via treesitter (arborist.nvim has no built-in
-- equivalent to nvim-treesitter's incremental_selection, so this is
-- reimplemented on top of core vim.treesitter).
local ts_select = require("config.treesitter-select")
map({ "n", "x" }, "<M-space>", ts_select.grow, { desc = "Init/Expand Selection" })
map("x", "<BS>", ts_select.shrink, { desc = "Shrink Selection" })

-- Go
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gomod",
  callback = function(ev)
    local buf = ev.buf
    local wkok, wk = pcall(require, "which-key")
    if wkok then
      wk.add({
        { "<localleader>g", group = "Go Mod", buffer = buf },
      })
    end
    map("n", "<localleader>gg", function()
      vim.cmd("split | terminal go get -u ./...")
      vim.cmd("startinsert")
    end, { desc = "⬇️ Go Mod: Update Packages", buffer = buf })

    map("n", "<localleader>gt", function()
      vim.cmd("split | terminal go mod tidy")
      vim.cmd("startinsert")
    end, { desc = "🧹 Go Mod: Tidy", buffer = buf })

    map("n", "<localleader>gu", function()
      vim.notify("🔎 Fetching latest Go version...", vim.log.levels.INFO, { title = "Go Mod" })
      vim.system(
        { "curl", "-fsSL", "https://go.dev/dl/?mode=json" },
        { text = true },
        vim.schedule_wrap(function(obj)
          if obj.code ~= 0 then
            vim.notify("❌ Failed to fetch Go versions", vim.log.levels.ERROR, { title = "Go Mod" })
            return
          end
          local ok, releases = pcall(vim.json.decode, obj.stdout)
          if not ok or type(releases) ~= "table" then
            vim.notify("❌ Could not parse go.dev/dl response", vim.log.levels.ERROR, { title = "Go Mod" })
            return
          end
          local latest
          for _, rel in ipairs(releases) do
            if rel.stable then
              latest = rel.version
              break
            end
          end
          if not latest then
            vim.notify("❌ No stable Go version found", vim.log.levels.ERROR, { title = "Go Mod" })
            return
          end
          local semver = latest:gsub("^go", "")
          local cmd = string.format("go mod edit -go=%s -toolchain=%s && go mod tidy", semver, latest)
          vim.cmd("split | terminal " .. cmd)
          vim.cmd("startinsert")
        end)
      )
    end, { desc = "🚀 Go Mod: Update Go Version & Toolchain to Latest", buffer = buf })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function(ev)
    local buf = ev.buf
    local wkok, wk = pcall(require, "which-key")
    if wkok then
      wk.add({
        { "<localleader>l", group = "Linter", buffer = buf },
        { "<localleader>g", group = "Go", buffer = buf },
      })
    end

    -- ==== Go (go.nvim) <localleader>g ==== --
    map("n", "<localleader>gf", "<cmd>GoFillStruct<cr>", { desc = "Fill Struct Fields", buffer = buf })
    map("n", "<localleader>ge", "<cmd>GoIfErr<cr>", { desc = "Add if err != nil", buffer = buf })
    map("n", "<localleader>gi", "<cmd>GoImpl<cr>", { desc = "Implement Interface", buffer = buf })
    map("n", "<localleader>ga", "<cmd>GoAddTag<cr>", { desc = "Add Struct Tags", buffer = buf })
    map("n", "<localleader>gA", "<cmd>GoRmTag<cr>", { desc = "Remove Struct Tags", buffer = buf })
    map("n", "<localleader>gT", "<cmd>GoModifyTag<cr>", { desc = "Modify Struct Tags", buffer = buf })
    map("n", "<localleader>go", "<cmd>GoAlt!<cr>", { desc = "Toggle Source/Test File", buffer = buf })
    map("n", "<localleader>gc", "<cmd>GoCmt<cr>", { desc = "Generate Function Comment", buffer = buf })

    -- Tests and debugging live on the universal <leader>t / <leader>d menus
    -- (see lua/config/testing.lua); Go-specific extras are registered there
    -- through `ft_extras.go`.

    -- ==== Linting <localleader>l ==== --
    local lint = require("lint")

    local function run_go_linter_with_feedback()
      vim.cmd("silent! update")
      lint.try_lint("golangci_lint")

      vim.defer_fn(function()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end

        local diagnostics = vim.diagnostic.get(buf)
        local issue_count = #diagnostics

        if issue_count == 0 then
          vim.notify("✅ golangci-lint: no issues found", vim.log.levels.INFO, { title = "Lint" })
          return
        end

        vim.notify(string.format("⚠️ golangci-lint: %d issue(s) found", issue_count), vim.log.levels.WARN, {
          title = "Lint",
        })
        vim.diagnostic.setloclist({ title = "Lint Diagnostics", open = true })
      end, 400)
    end

    map("n", "<localleader>ll", function()
      run_go_linter_with_feedback()
    end, { desc = "🔍 Lint: Run golangci-lint (manual + results)", buffer = buf })

    map("n", "<localleader>lr", function()
      vim.diagnostic.reset()
      print("🧹 Cleared diagnostics")
    end, { desc = "🧹 Lint: Reset diagnostics", buffer = buf })

    map("n", "<localleader>ld", function()
      vim.diagnostic.open_float(nil, { focus = true, scope = "cursor" })
    end, { desc = "💡 Lint: Show diagnostic under cursor", buffer = buf })

    map("n", "<localleader>lD", function()
      vim.diagnostic.setloclist({ title = "Lint Diagnostics", open = true })
    end, { desc = "🧭 Lint: Open diagnostics list", buffer = buf })
  end,
})

-- ==== Octo ==== --
pcall(function()
  local wk = require("which-key")
  wk.add({
    { "<leader>o", group = "Octo (🐙 GitHub)" },
    { "<leader>op", group = "🖖🏼 PRs" },
    { "<leader>oi", group = "⚠️ Issues" },
  })
end)

-- PRs
map("n", "<leader>opp", "<cmd>Octo pr list<cr>", { desc = "PR: List" })
map("n", "<leader>opn", function()
  vim.cmd("botright split | resize 15")
  vim.cmd("terminal gh pr create --fill --editor")
  vim.cmd("startinsert")
end, { desc = "PR: Create (edit body first)" })
map("n", "<leader>opv", "<cmd>Octo pr view<cr>", { desc = "PR: View" })
map("n", "<leader>opc", "<cmd>Octo pr checkout<cr>", { desc = "PR: Checkout" })
map("n", "<leader>opk", "<cmd>Octo pr checks<cr>", { desc = "PR: Checks" })
map("n", "<leader>opm", "<cmd>Octo pr merge<cr>", { desc = "PR: Merge" })
map("n", "<leader>opr", "<cmd>Octo review start<cr>", { desc = "Review: Start" })
map("n", "<leader>ops", "<cmd>Octo review submit<cr>", { desc = "Review: Submit" })
map("n", "<leader>opb", "<cmd>Octo pr browser<cr>", { desc = "Open in Browser" })
map("n", "<leader>opl", "<cmd>Octo pr reload<cr>", { desc = "Reload PR" })

map("n", "<leader>oa", ":Octo assignee add mesirendon<cr>", { desc = "PR: Assign me" })
map("n", "<leader>or", ":Octo reviewer add ", { desc = "PR: Add Reviewe(s)" })

-- Issues
map("n", "<leader>oil", "<cmd>Octo issue list<cr>", { desc = "Issue: List" })
map("n", "<leader>oic", "<cmd>Octo issue create<cr>", { desc = "Issue: Create" })
map("n", "<leader>oiv", "<cmd>Octo issue view<cr>", { desc = "Issue: View Current" })

-- ==== PlantUML ==== --
vim.api.nvim_create_autocmd("FileType", {
  pattern = "plantuml",
  callback = function(ev)
    local buf = ev.buf
    local wkok, wk = pcall(require, "which-key")
    if wkok then
      wk.add({
        { "<localleader>u", group = "PlantUML", buffer = buf },
      })
    end

    -- Open/focus preview (most previewers refresh on :w)
    map("n", "<localleader>up", "<cmd>PlantumlOpen<cr>", {
      desc = "🖼️ PlantUML: Open Preview",
      buffer = buf,
    })

    -- Force a refresh by saving (useful if you disable autosave)
    map("n", "<localleader>ur", "<cmd>silent! write<cr>", {
      desc = "🔄 PlantUML: Reload (save)",
      buffer = buf,
    })

    -- Optional: export diagram
    map("n", "<localleader>us", "<cmd>PlantumlSave<cr>", {
      desc = "💾 PlantUML: Save/Export",
      buffer = buf,
    })

    local function save_diagram_here()
      local src = vim.api.nvim_buf_get_name(buf)
      if src == "" then
        vim.notify("Buffer has no file name. Save the .puml file first.", vim.log.levels.WARN)
        return
      end

      -- ask format
      local formats = { "svg", "png" }
      vim.ui.select(formats, { prompt = "PlantUML export format:" }, function(fmt)
        if not fmt then
          return
        end

        local dir = vim.fn.fnamemodify(src, ":p:h")
        local base = vim.fn.fnamemodify(src, ":t:r")
        local out = string.format("%s/%s.%s", dir, base, fmt)

        -- ensure latest content is saved before exporting
        vim.cmd("silent! write")

        -- PlantumlSave expects: :PlantumlSave {outfile} {format}
        vim.cmd(string.format("PlantumlSave %s %s", vim.fn.fnameescape(out), fmt))
        vim.notify("Saved: " .. out)
      end)
    end

    -- Keybinding: export diagram next to file
    vim.keymap.set("n", "<localleader>us", save_diagram_here, {
      buffer = buf,
      desc = "PlantUML: Export (choose format) to same folder",
      silent = true,
      noremap = true,
    })

    -- "Live reload": autosave on edit with debounce, for *.puml
    -- This triggers preview refresh because the preview plugin updates on save.
    local group = vim.api.nvim_create_augroup("PlantUMLLiveReload_" .. buf, { clear = true })

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = group,
      buffer = buf,
      callback = function()
        vim.defer_fn(function()
          -- buffer may have been deleted
          if not vim.api.nvim_buf_is_valid(buf) then
            return
          end
          if vim.bo[buf].modified then
            vim.cmd("silent! write")
          end
        end, 600) -- debounce ms
      end,
    })
  end,
})
