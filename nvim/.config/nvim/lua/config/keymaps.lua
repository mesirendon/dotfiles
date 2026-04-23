-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local opts = { silent = true, noremap = true }

map("n", "+", "<C-a>", opts)
map("n", "-", "<C-x>", opts)

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
    local nt = require("neotest")
    local dap = require("dap")
    local dapui = require("dapui")
    local wkok, wk = pcall(require, "which-key")
    if wkok then
      wk.add({
        { "<localleader>t", group = "Tests", buffer = buf },
        { "<localleader>d", group = "Debug", buffer = buf },
        { "<localleader>l", group = "Linter", buffer = buf },
      })
    end

    local function term_run(argv, name)
      vim.cmd("botright split | resize 15")
      vim.cmd("terminal")
      local chan = vim.b.terminal_job_id
      if chan then
        local line = (type(argv) == "table") and table.concat(argv, " ") or argv
        vim.fn.chansend(chan, line .. "\n")
      end
      if name then
        vim.api.nvim_buf_set_name(0, name)
      end
      vim.cmd("startinsert")
    end

    local function run_all_with_coverage()
      vim.ui.input({ prompt = "Build tags (optional, space/comma-separated): " }, function(input)
        local tags = (input and input:match("%S")) and (input:gsub(",", " "):gsub("%s+", " ")) or nil

        local argv = { "go", "test", "./...", "-cover", "-count=1", "-coverprofile=coverage.out" }
        if tags then
          table.insert(argv, "-tags")
          table.insert(argv, tags)
        end

        term_run(argv, "go test (coverage)")
      end)
    end

    -- ==== Testing <localleader>t ==== --
    map(
      "n",
      "<localleader>tA",
      run_all_with_coverage,
      { desc = "🔦 Go Test Run: All (coverage, optional -tags)", buffer = buf }
    )

    map("n", "<localleader>tC", function()
      term_run({ "go", "tool", "cover", "-func=coverage.out" }, "go coverage summary")
    end, { desc = "📊 Coverage: Summary (coverage.out)", buffer = buf })

    map("n", "<localleader>tH", function()
      vim.fn.jobstart({ "go", "tool", "cover", "-html=coverage.out" }, { detach = true })
    end, { desc = "🖼️ Coverage: HTML (browser)", buffer = buf })

    map("n", "<localleader>ta", function()
      nt.run.run({ suite = true })
    end, { desc = "🧮 Go Test Run: All (suite)", buffer = buf })

    map("n", "<localleader>tp", function()
      nt.run.run((vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":h")))
    end, { desc = "📦 Go Test Run: Package (dir)", buffer = buf })

    map("n", "<localleader>tf", function()
      nt.run.run(vim.fn.expand("%"))
    end, { desc = "📄 Go Test Run: File", buffer = buf })

    map("n", "<localleader>tn", function()
      nt.run.run()
    end, { desc = "🧭 Go Test Run: Nearest (subtest)", buffer = buf })

    map("n", "<localleader>tv", function()
      nt.run.run({ suite = false, strategy = "integrated", args = { "-v" } })
    end, { desc = "📃 Run nearest Go test verbose", buffer = buf })

    map("n", "<localleader>tu", function()
      local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":h")
      term_run({ "go", "test", dir, "-count=1", "-update" }, "go test (pkg -update)")
    end, { desc = "📦 Go Test: Package (-update snapshots)", buffer = buf })

    map("n", "<localleader>tl", function()
      nt.run.run_last()
    end, { desc = "📍 Go Test Run: Last", buffer = buf })

    map("n", "<localleader>to", function()
      nt.output.open({ enter = false, short = true })
    end, { desc = "🖥️ Output: Last", buffer = buf })

    map("n", "<localleader>ts", function()
      nt.summary.toggle()
    end, { desc = "📝 Summary: Toggle", buffer = buf })

    map("n", "<localleader>td", function()
      nt.run.run({ strategy = "dap", suite = false })
    end, { desc = "🐞 Debug: Nearest", buffer = buf })

    -- ==== Debugging <localleader>d ==== --
    -- Breakpoints --
    map("n", "<localleader>db", function()
      dap.toggle_breakpoint()
    end, { desc = "⛔️ Breakpoint: Toggle", buffer = buf })

    map("n", "<localleader>dB", function()
      vim.ui.input({ prompt = "Breakpoint condition: " }, function(cond)
        if cond and #cond > 0 then
          dap.set_breakpoint(cond)
        end
      end)
    end, { desc = "⚙️ Breakpoint: Conditional", buffer = buf })

    map("n", "<localleader>dC", function()
      dap.clear_breakpoints()
    end, { desc = "🧹 Breakpoint: Clear All", buffer = buf })

    -- Controls --
    map("n", "<localleader>dc", function()
      dap.continue()
    end, { desc = "▶️ Start/Continue", buffer = buf })

    map("n", "<localleader>di", function()
      dap.step_into()
    end, { desc = "⤵️ Step Into", buffer = buf })

    map("n", "<localleader>do", function()
      dap.step_over()
    end, { desc = "⏭️ Step Over", buffer = buf })

    map("n", "<localleader>dO", function()
      dap.step_out()
    end, { desc = "⤴️ Step Out", buffer = buf })

    map("n", "<localleader>dr", function()
      dap.restart()
    end, { desc = "🔁 Restart", buffer = buf })

    map("n", "<localleader>dS", function()
      dap.terminate()
    end, { desc = "🛑 Stop", buffer = buf })

    -- UI/Introspection
    map("n", "<localleader>du", function()
      dapui.toggle()
    end, { desc = "💻 DAP UI: Toggle", buffer = buf })

    map("n", "<localleader>ds", function()
      dapui.open({})
    end, { desc = "👓 View: Scopes/Stacks/Breakpoints", buffer = buf })

    map("n", "<localleader>dv", function()
      require("dap.ui.widgets").hover()
    end, { desc = "🔬 Inspect Variable (hover)", buffer = buf })

    -- ==== Linting <localleader>l ==== --
    local lint = require("lint")

    local function run_go_linter_with_feedback()
      vim.cmd("silent! update")
      lint.try_lint("golangcilint")

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
