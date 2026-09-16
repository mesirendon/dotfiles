return {
  {
    "rezniqov/soviet.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        sidebars = "dark",
        floats = "dark",
      },
    },
    config = function(_, opts)
      require("soviet").setup(opts)

      -- Persist the last chosen variant across sessions.
      local state_file = vim.fn.stdpath("state") .. "/soviet-variant"

      local function read_variant()
        local ok, lines = pcall(vim.fn.readfile, state_file)
        local v = ok and lines[1] or nil
        return (v == "light" or v == "dark") and v or "dark"
      end

      local function apply(variant, persist)
        variant = (variant == "light") and "light" or "dark"
        vim.o.background = variant
        vim.cmd.colorscheme("soviet-" .. variant)
        if persist then
          pcall(vim.fn.writefile, { variant }, state_file)
        end
      end

      apply(read_variant(), false)

      local function current()
        return (vim.o.background == "light") and "light" or "dark"
      end

      vim.api.nvim_create_user_command("ThemeToggle", function()
        apply(current() == "dark" and "light" or "dark", true)
      end, { desc = "Toggle soviet light/dark variant" })

      vim.api.nvim_create_user_command("ThemeDark", function()
        apply("dark", true)
      end, { desc = "Use soviet-dark" })

      vim.api.nvim_create_user_command("ThemeLight", function()
        apply("light", true)
      end, { desc = "Use soviet-light" })
    end,
  },
}
