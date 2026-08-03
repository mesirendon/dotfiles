-- Terminal management (toggleterm.nvim). Owns the <leader>;* group, <C-/>,
-- and <leader>gg / <leader>gG (lazygit).
-- Directory resolution goes through util.terminal. Note this group inverts the
-- picker/explorer convention on purpose: lowercase = cwd, uppercase = root dir.
local Term = function(opts)
  return function()
    require("util.terminal").open(opts)
  end
end

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec", "TermSelect", "ToggleTermToggleAll" },
    keys = {
      -- floating (primary)
      { "<leader>;f", Term({ direction = "float", root = false }), desc = "Float Terminal (cwd)" },
      { "<leader>;F", Term({ direction = "float" }), desc = "Float Terminal (Root Dir)" },
      -- bottom
      { "<leader>;h", Term({ direction = "horizontal", root = false }), desc = "Bottom Terminal (cwd)" },
      { "<leader>;H", Term({ direction = "horizontal" }), desc = "Bottom Terminal (Root Dir)" },
      -- right
      { "<leader>;v", Term({ direction = "vertical", root = false }), desc = "Right Terminal (cwd)" },
      { "<leader>;V", Term({ direction = "vertical" }), desc = "Right Terminal (Root Dir)" },
      -- management
      { "<leader>;s", "<cmd>TermSelect<cr>", desc = "Select Terminal" },
      {
        "<leader>;n",
        function()
          require("util.terminal").new({ root = false })
        end,
        desc = "New Terminal (cwd)",
      },
      {
        "<leader>;N",
        function()
          require("util.terminal").new()
        end,
        desc = "New Terminal (Root Dir)",
      },
      {
        "<c-/>",
        Term({ direction = "float", root = false }),
        mode = { "n", "t" },
        desc = "Toggle Float Terminal (cwd)",
      },
      -- lazygit
      {
        "<leader>gg",
        function()
          require("util.terminal").lazygit({ root = false })
        end,
        desc = "Lazygit (cwd)",
      },
      {
        "<leader>gG",
        function()
          require("util.terminal").lazygit()
        end,
        desc = "Lazygit (Root Dir)",
      },
    },
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.4)
        end
      end,
      open_mapping = false, -- keys are declared explicitly above
      direction = "float",
      float_opts = {
        border = "rounded",
        winblend = 0,
        width = function()
          return math.floor(vim.o.columns * 0.85)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.85)
        end,
      },
      shade_terminals = false, -- catppuccin already themes the terminal bg
      start_in_insert = true,
      persist_size = true,
      persist_mode = false,
      close_on_exit = true,
      autochdir = false,
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      vim.api.nvim_create_autocmd("TermOpen", {
        group = vim.api.nvim_create_augroup("toggleterm_keymaps", { clear = true }),
        pattern = "term://*toggleterm#*",
        callback = function(event)
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
          end
          map("t", "<esc>", [[<C-\><C-n>]], "Normal Mode")
          map("t", "<C-h>", [[<cmd>wincmd h<cr>]], "Go to Left Window")
          map("t", "<C-j>", [[<cmd>wincmd j<cr>]], "Go to Lower Window")
          map("t", "<C-k>", [[<cmd>wincmd k<cr>]], "Go to Upper Window")
          map("t", "<C-l>", [[<cmd>wincmd l<cr>]], "Go to Right Window")
          map("n", "q", "<cmd>close<cr>", "Close Terminal")

          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
          vim.opt_local.signcolumn = "no"
          vim.opt_local.spell = false
        end,
      })
    end,
  },
}
