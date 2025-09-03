return {
  { "rmehri01/onenord.nvim", name = "onenord", lazy = false, priority = 1000 },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        -- one place to decide which scheme to use
        local function want_scheme()
          local h = tonumber(os.date("%H"))
          return (h >= 7 and h < 17) and "onenord-light" or "onenord"
        end

        -- apply only if it actually changes
        local function apply()
          local scheme = want_scheme()
          if vim.g.colors_name ~= scheme then
            vim.cmd.colorscheme(scheme)
          end
        end

        -- initial apply at startup
        apply()

        -- define commands once
        if not vim.g._onenord_theme_cmds then
          vim.api.nvim_create_user_command("ThemeDay", function()
            vim.cmd.colorscheme("onenord-light")
          end, {})
          vim.api.nvim_create_user_command("ThemeNight", function()
            vim.cmd.colorscheme("onenord")
          end, {})
          vim.g._onenord_theme_cmds = true
        end

        -- re-apply when you refocus Neovim (cheap + reliable)
        vim.api.nvim_create_autocmd("FocusGained", { callback = apply })

        -- periodic check (every minute) without libuv objects
        local function tick()
          apply()
          vim.defer_fn(tick, 60 * 1000) -- check every 60s
        end
        vim.api.nvim_create_autocmd("VimEnter", { callback = tick })
      end,
    },
  },
}
