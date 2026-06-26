-- Go first IDE setup + common languages
return {
  -- 1) Making sure dev tools are installed
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_extend("force", opts.ensure_installed or {}, {
        -- GitUI
        "gitui",
        -- Go
        "gopls",
        "gofumpt",
        "goimports",
        "golangci-lint",
        "gotestsum",
        "delve",
        -- TS/JS
        "vtsls",
        "prettierd",
        "eslint_d",
        -- Lua
        "lua-language-server",
        "stylua",
        -- Bash / Shell
        "bash-language-server",
        "shfmt",
        "shellcheck",
        -- YAML / Docker
        "yaml-language-server",
        "dockerfile-language-server",
      })
    end,
  },
  {
    "stevearc/aerial.nvim",
    opts = {
      layout = {
        min_width = 50,
        max_width = { 80, 0.4 },
      },
    },
  },
  -- 2) LSP Servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      folds = {
        enabled = true,
      },
      servers = {
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              analyses = { unusedparams = true, shadow = true, unusedwrite = true, useany = true },
              staticcheck = true,
              hints = {
                parameterNames = true,
                assignVariableTypes = true,
                constantValues = true,
                functionTypeParameters = true,
              },
            },
          },
        },
        vtsls = {},
        bashls = {},
        yamlls = {
          settings = {
            yaml = {
              schemas = {
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*.yml",
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose*.yml",
              },
              validate = true,
              hover = true,
              completion = true,
            },
          },
        },
        dockerls = {},
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false },
            },
          },
        },
      },
    },
  },
  -- 3) Formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "gofumpt", "goimports" },
        lua = { "stylua" },
        javascript = { "prettierd", "prettier" },
        typescript = { "prettierd", "prettier" },
        json = { "prettierd", "prettier" },
        yaml = { "prettierd", "prettier" },
        html = { "prettierd", "prettier" },
        tmpl = { "templ", "prettierd", "prettier" },
        css = { "prettierd", "prettier" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
      },
    },
  },
  { "ngynkvn/gotmpl.nvim", opts = {} },
  -- 4) Linting
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        go = { "golangcilint" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        zsh = { "shellcheck" },
      },
    },
  },
  -- 5) Debugging for Go
  { "mfussenegger/nvim-dap" },
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    config = function()
      local dap = require("dap")

      dap.adapters.go = {
        type = "server",
        port = "${port}",
        executable = {
          command = "dlv",
          args = { "dap", "-l", "127.0.0.1:${port}" },
          env = {
            AWS_PROFILE = os.getenv("AWS_PROFILE"),
            AWS_REGION = os.getenv("AWS_REGION"),
          },
        },
      }
      require("dap-go").setup({
        dap_configurations = {
          {
            type = "go",
            main = "Debug Main",
            request = "launch",
            program = "${workspaceFolder}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "go",
            main = "Debug Current File",
            request = "launch",
            program = "${file}",
            cwd = "${fileDirname}",
          },
        },
      })
      dap.defaults.fallback.terminal_win_cmd = "10split new"
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    opts = {
      controls = {
        element = "repl",
        enabled = true,
        icons = {
          disconnect = "",
          pause = "",
          play = "",
          run_last = "",
          step_back = "",
          step_into = "",
          step_out = "",
          step_over = "",
          terminate = "",
        },
      },
      element_mappings = {},
      expand_lines = true,
      floating = {
        border = "single",
        mappings = {
          close = { "q", "<Esc>" },
        },
      },
      force_buffers = true,
      icons = {
        collapsed = "",
        current_frame = "",
        expanded = "",
      },
      layouts = {
        {
          elements = {
            {
              id = "scopes",
              size = 0.25,
            },
            {
              id = "breakpoints",
              size = 0.25,
            },
            {
              id = "stacks",
              size = 0.25,
            },
            {
              id = "watches",
              size = 0.25,
            },
          },
          position = "left",
          size = 40,
        },
        {
          elements = {
            {
              id = "repl",
              size = 0.5,
            },
            {
              id = "console",
              size = 0.5,
            },
          },
          position = "bottom",
          size = 10,
        },
      },
      mappings = {
        edit = "e",
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        repl = "r",
        toggle = "t",
      },
      render = {
        indent = 1,
        max_value_lines = 100,
      },
    },
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup(opts)
      dap.listeners.after.event_initialized["dapui_auto"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_auto"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_auto"] = function()
        dapui.close()
      end

      vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "⚠️", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped", { text = "▶️", texthl = "DiagnosticInfo", linehl = "Visual" })
    end,
  },
  { "theHamsta/nvim-dap-virtual-text", config = true },
}
