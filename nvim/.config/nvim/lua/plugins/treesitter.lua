return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    vim.opt.foldmethod = "expr"
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

    local parsers = {
      "bash",
      "c",
      "css",
      "csv",
      "diff",
      "dockerfile",
      "editorconfig",
      "git_config",
      "git_rebase",
      "gitattributes",
      "gitcommit",
      "gitignore",
      "go",
      "gomod",
      "gosum",
      "gotmpl",
      "gowork",
      "html",
      "http",
      "javascript",
      "jsdoc",
      "json",
      "jsonc",
      "lua",
      "luadoc",
      "luap",
      "markdown",
      "markdown_inline",
      "python",
      "query",
      "regex",
      "scss",
      "sql",
      "ssh_config",
      "styled",
      "templ",
      "toml",
      "tsx",
      "typescript",
      "vim",
      "vimdoc",
      "yaml",
      "zig",
    }

    require("nvim-treesitter").install(parsers)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = parsers,
      callback = function(args)
        vim.treesitter.start()
      end,
    })
  end,
  opts = {
    ensure_installed = {
      "go",
      "gomod",
      "gosum",
      "gowork",
      "bash",
      "html",
      "javascript",
      "json",
      "lua",
      "markdown",
      "markdown_inline",
      "regex",
      "tsx",
      "typescript",
      "vim",
      "yaml",
      "toml",
    },
    sync_install = false,
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        scope_incremental = false,
        init_selection = "<M-space>",
        node_incremental = "<M-space>",
        node_decremental = "<BS>",
      },
    },
    textobjects = {
      move = {
        enable = true,
        goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
        goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
        goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
        goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
      },
    },
  },
}
