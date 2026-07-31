-- UI stack ported from LazyVim: bufferline, lualine, noice, mini.icons, nui.
local icons = require("config.icons").icons
local Util = require("util")

-- Nerd Font glyphs in the Private Use Area are written as escapes rather than literal
-- characters: pasted literals get silently dropped somewhere in this repo's tooling
-- (see the empty `glyph = ""` strings that reached git in the mini.icons spec below).
local FLASK = "\u{f0c3}" -- nf-fa-flask
local DOCKER = "\u{e7b0}" -- nf-dev-docker
local CONFIG = "\u{e615}" -- nf-seti-config

return {
  -- Buffer tabs
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = function()
      local keys = {
        { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
        { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
        { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
        { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
        { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
        { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
        { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
        { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
        { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
        { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
        -- Pick: letters overlay each tab only while the prompt is active
        { "<leader>bj", "<cmd>BufferLinePick<cr>", desc = "Pick Buffer" },
        { "<leader>bJ", "<cmd>BufferLinePickClose<cr>", desc = "Pick Buffer to Close" },
        { "gb", "<cmd>BufferLinePick<cr>", desc = "Pick Buffer" },
        -- Reorder
        { "<A-Left>", "<cmd>BufferLineMovePrev<cr>", desc = "Move Buffer Left" },
        { "<A-Right>", "<cmd>BufferLineMoveNext<cr>", desc = "Move Buffer Right" },
        -- Sort
        { "<leader>bs", "", desc = "+sort" },
        { "<leader>bse", "<cmd>BufferLineSortByExtension<cr>", desc = "Sort by Extension" },
        { "<leader>bsd", "<cmd>BufferLineSortByDirectory<cr>", desc = "Sort by Directory" },
        { "<leader>bsr", "<cmd>BufferLineSortByRelativeDirectory<cr>", desc = "Sort by Relative Directory" },
        { "<leader>bst", "<cmd>BufferLineSortByTabs<cr>", desc = "Sort by Tabs" },
        -- Groups
        { "<leader>bg", "", desc = "+groups" },
        { "<leader>bgg", "<cmd>BufferLineGroupToggle Go<cr>", desc = "Toggle Go Group" },
        { "<leader>bgt", "<cmd>BufferLineGroupToggle Tests<cr>", desc = "Toggle Tests Group" },
      }
      for i = 1, 9 do
        table.insert(keys, {
          ("<A-%d>"):format(i),
          ("<cmd>BufferLineGoToBuffer %d<cr>"):format(i),
          desc = ("Go to Buffer %d"):format(i),
        })
      end
      table.insert(keys, { "<A-0>", "<cmd>BufferLineGoToBuffer -1<cr>", desc = "Go to Last Buffer" })
      return keys
    end,
    opts = function()
      -- Take the Go group's colour from devicons so it tracks upstream. The glyph itself
      -- comes from devicons per-buffer, so only the colour is needed here.
      local go_color = "#00ADD8"
      local ok, devicons = pcall(require, "nvim-web-devicons")
      if ok then
        local _, color = devicons.get_icon_color_by_filetype("go", { default = true })
        go_color = color or go_color
      end

      local groups = require("bufferline.groups")

      return {
        options = {
          close_command = function(n)
            Snacks.bufdelete(n)
          end,
          right_mouse_command = function(n)
            Snacks.bufdelete(n)
          end,
          diagnostics = "nvim_lsp",
          always_show_bufferline = false,
          indicator = { style = "underline" },
          separator_style = "slant",
          -- Baseline only: manual moves and the SortBy commands set `custom_sort`,
          -- which short-circuits this (see bufferline/sorters.lua).
          sort_by = "insert_after_current",
          move_wraps_at_ends = true,
          hover = { enabled = true, delay = 200, reveal = { "close" } },
          -- Home row first, so the letters picked for buffers whose first letter is
          -- already taken land under your fingers. Also restores the `n` upstream omits.
          pick = { alphabet = "asdfjklghnmxcvbziowerutyqp" },
          diagnostics_indicator = function(_, _, diag)
            local ret = (diag.error and icons.diagnostics.Error .. diag.error .. " " or "")
              .. (diag.warning and icons.diagnostics.Warn .. diag.warning or "")
            return vim.trim(ret)
          end,
          offsets = {
            { filetype = "snacks_layout_box" },
          },
          get_element_icon = function(o)
            -- devicons matches whole filenames then extensions, so `*_test.go` has to
            -- be special-cased here; returning nil falls through to the devicons lookup.
            if o.path and o.path:match("_test%.go$") then
              return FLASK, "BufferlineGoTestIcon"
            end
            return icons.ft[o.filetype]
          end,
          groups = {
            options = { toggle_hidden_on_enter = true },
            items = {
              groups.builtin.pinned:with({ icon = "\u{f08d}" }),
              -- No `icon` on these two on purpose: bufferline renders a group's icon on
              -- *every* buffer in it (groups.lua:M.component), which would double up with
              -- the per-tab icon. The gopher/flask above already carry the distinction.
              {
                -- Matchers must be mutually exclusive: groups are resolved with an
                -- unordered pairs() loop, so `priority` cannot break a tie.
                name = "Go",
                highlight = { fg = go_color, sp = go_color },
                matcher = function(buf)
                  return buf.path and buf.path:match("%.go$") and not buf.path:match("_test%.go$")
                end,
              },
              {
                name = "Tests",
                highlight = { fg = "#a6e3a1", sp = "#a6e3a1" },
                matcher = function(buf)
                  return buf.path and buf.path:match("_test%.go$")
                end,
              },
              groups.builtin.ungrouped,
            },
          },
        },
      }
    end,
    config = function(_, opts)
      require("bufferline").setup(opts)

      local function set_hl()
        vim.api.nvim_set_hl(0, "BufferlineGoTestIcon", { fg = "#a6e3a1" })
      end
      set_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    init = function()
      vim.g.lualine_laststatus = vim.o.laststatus
      if vim.fn.argc(-1) > 0 then
        vim.o.statusline = " "
      else
        vim.o.laststatus = 0
      end
    end,
    opts = function()
      vim.o.laststatus = vim.g.lualine_laststatus

      local opts = {
        options = {
          theme = "auto",
          globalstatus = vim.o.laststatus == 3,
          disabled_filetypes = { statusline = { "dashboard", "snacks_dashboard" } },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = {
            {
              "diagnostics",
              symbols = {
                error = icons.diagnostics.Error,
                warn = icons.diagnostics.Warn,
                info = icons.diagnostics.Info,
                hint = icons.diagnostics.Hint,
              },
            },
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            { "filename", path = 1 },
          },
          lualine_x = {
            {
              function()
                return require("noice").api.status.command.get()
              end,
              cond = function()
                return package.loaded["noice"] and require("noice").api.status.command.has()
              end,
              color = function()
                return { fg = Snacks.util.color("Statement") }
              end,
            },
            {
              function()
                return require("noice").api.status.mode.get()
              end,
              cond = function()
                return package.loaded["noice"] and require("noice").api.status.mode.has()
              end,
              color = function()
                return { fg = Snacks.util.color("Constant") }
              end,
            },
            {
              function()
                return "  " .. require("dap").status()
              end,
              cond = function()
                return package.loaded["dap"] and require("dap").status() ~= ""
              end,
              color = function()
                return { fg = Snacks.util.color("Debug") }
              end,
            },
            {
              require("lazy.status").updates,
              cond = require("lazy.status").has_updates,
              color = function()
                return { fg = Snacks.util.color("Special") }
              end,
            },
            {
              "diff",
              symbols = {
                added = icons.git.added,
                modified = icons.git.modified,
                removed = icons.git.removed,
              },
              source = function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                  return { added = gitsigns.added, modified = gitsigns.changed, removed = gitsigns.removed }
                end
              end,
            },
          },
          lualine_y = {
            { "progress", separator = " ", padding = { left = 1, right = 0 } },
            { "location", padding = { left = 0, right = 1 } },
          },
          lualine_z = {
            function()
              return " " .. os.date("%R")
            end,
          },
        },
        extensions = { "lazy", "fzf" },
      }

      -- Show Trouble document symbols in lualine
      if vim.g.trouble_lualine and Util.has("trouble.nvim") then
        local trouble = require("trouble")
        local symbols = trouble.statusline({
          mode = "symbols",
          groups = {},
          title = false,
          filter = { range = true },
          format = "{kind_icon}{symbol.name:Normal}",
          hl_group = "lualine_c_normal",
        })
        table.insert(opts.sections.lualine_c, {
          symbols and symbols.get,
          cond = function()
            return vim.b.trouble_lualine ~= false and symbols.has()
          end,
        })
      end

      return opts
    end,
  },

  -- Replaces the UI for messages, cmdline and the popupmenu
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
            },
          },
          view = "mini",
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
      },
    },
    keys = {
      { "<leader>sn", "", desc = "+noice" },
      {
        "<S-Enter>",
        function()
          require("noice").redirect(vim.fn.getcmdline())
        end,
        mode = "c",
        desc = "Redirect Cmdline",
      },
      {
        "<leader>snl",
        function()
          require("noice").cmd("last")
        end,
        desc = "Noice Last Message",
      },
      {
        "<leader>snh",
        function()
          require("noice").cmd("history")
        end,
        desc = "Noice History",
      },
      {
        "<leader>sna",
        function()
          require("noice").cmd("all")
        end,
        desc = "Noice All",
      },
      {
        "<leader>snd",
        function()
          require("noice").cmd("dismiss")
        end,
        desc = "Dismiss All",
      },
      {
        "<c-f>",
        function()
          if not require("noice.lsp").scroll(4) then
            return "<c-f>"
          end
        end,
        silent = true,
        expr = true,
        desc = "Scroll Forward",
        mode = { "i", "n", "s" },
      },
      {
        "<c-b>",
        function()
          if not require("noice.lsp").scroll(-4) then
            return "<c-b>"
          end
        end,
        silent = true,
        expr = true,
        desc = "Scroll Backward",
        mode = { "i", "n", "s" },
      },
    },
    config = function(_, opts)
      if vim.o.filetype == "lazy" then
        vim.cmd([[messages clear]])
      end
      require("noice").setup(opts)
    end,
  },

  -- icons
  {
    "nvim-mini/mini.icons",
    lazy = true,
    opts = {
      file = {
        [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
        ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
      },
      filetype = {
        dotenv = { glyph = "", hl = "MiniIconsYellow" },
      },
    },
  },

  -- The `nvim-web-devicons` mock that mini.icons used to install via package.preload
  -- shadowed the real plugin, so it is gone; these overrides carry over the glyphs
  -- the mini.icons spec above customises.
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    opts = {
      override = {
        keep = { icon = "󰊢", color = "#6e738d", name = "Keep" },
      },
      override_by_filename = {
        [".keep"] = { icon = "󰊢", color = "#6e738d", name = "Keep" },
        -- The mini.icons entries these replace reached git with empty glyph strings,
        -- so these two are fresh picks rather than a faithful carry-over.
        ["devcontainer.json"] = { icon = DOCKER, color = "#89b4fa", name = "Devcontainer" },
        [".env"] = { icon = CONFIG, color = "#f9e2af", name = "Dotenv" },
      },
    },
  },

  -- ui components
  { "MunifTanjim/nui.nvim", lazy = true },
}
