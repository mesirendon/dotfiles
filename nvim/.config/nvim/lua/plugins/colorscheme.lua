return {
  -- Themes
  { "rmehri01/onenord.nvim", name = "onenord", lazy = false, priority = 1000 },
  { "nordtheme/vim", name = "nord", lazy = false, priority = 1000 },

  -- Picker / day-night logic
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        -- tweak Nord (optional)
        vim.g.nord_borders = true
        vim.g.nord_italic = true
        vim.g.nord_bold = true
        -- vim.g.nord_disable_background = true  -- uncomment if you want a transparent bg

        -- decide which theme we want right now
        local day_start = tonumber(vim.g.theme_day_start or 7)
        local day_stop = tonumber(vim.g.theme_day_stop or 17)
        local hour = tonumber(os.date("%H"))
        local is_day = hour >= day_start and hour < day_stop

        local function apply()
          local scheme = is_day and "onenord-light" or "nord"
          if vim.g.colors_name ~= scheme then
            vim.cmd.colorscheme(scheme)
          end
        end

        apply()

        -- define handy commands once
        if not vim.g._daynight_cmds then
          vim.api.nvim_create_user_command("ThemeDay", function()
            vim.cmd.colorscheme("onenord-light")
          end, {})
          vim.api.nvim_create_user_command("ThemeNight", function()
            vim.cmd.colorscheme("nord")
          end, {})
          vim.api.nvim_create_user_command("ThemeDayHours", function(opts)
            local a = opts.fargs
            if #a ~= 2 then
              vim.notify("Usage: :ThemeDayHours <startHour> <stopHour>", vim.log.levels.WARN)
              return
            end
            local s, e = tonumber(a[1]), tonumber(a[2])
            if not (s and e and s >= 0 and s <= 23 and e >= 0 and e <= 23) then
              vim.notify("Hours must be 0..23", vim.log.levels.WARN)
              return
            end
            vim.g.theme_day_start, vim.g.theme_day_stop = s, e
            -- re-apply immediately using new window
            local h = tonumber(os.date("%H"))
            vim.cmd.colorscheme((h >= s and h < e) and "onenord-light" or "nord")
          end, { nargs = "+" })
          vim.g._daynight_cmds = true
        end

        -- re-apply when you refocus Neovim (keeps it in sync without timers)
        local grp = vim.api.nvim_create_augroup("ThemeDayNight", { clear = true })
        vim.api.nvim_create_autocmd("FocusGained", {
          group = grp,
          callback = function()
            local s = tonumber(vim.g.theme_day_start or 7)
            local e = tonumber(vim.g.theme_day_stop or 17)
            local h = tonumber(os.date("%H"))
            vim.cmd.colorscheme((h >= s and h < e) and "onenord-light" or "nord")
          end,
        })
      end,
    },
  },
}
