-- Go first IDE setup + common languages

local function vtsls_locations(client, command, arguments)
  client:request("workspace/executeCommand", { command = command, arguments = arguments }, function(err, result)
    if err or not result or vim.tbl_isempty(result) then
      vim.notify(err and err.message or "No locations found", vim.log.levels.INFO, { title = "vtsls" })
      return
    end
    if #result == 1 then
      vim.lsp.util.show_document(result[1], client.offset_encoding, { focus = true })
      return
    end
    vim.fn.setqflist({}, " ", {
      title = command,
      items = vim.lsp.util.locations_to_items(result, client.offset_encoding),
    })
    Snacks.picker.qflist()
  end)
end

local function source_action(kind)
  return function()
    vim.lsp.buf.code_action({ apply = true, context = { only = { kind }, diagnostics = {} } })
  end
end

local ts_inlay_hints = {
  enumMemberValues = { enabled = true },
  functionLikeReturnTypes = { enabled = true },
  parameterNames = { enabled = "literals" },
  parameterTypes = { enabled = true },
  propertyDeclarationTypes = { enabled = true },
  variableTypes = { enabled = false },
}

return {
  -- 1) Making sure dev tools are installed
  {
    "mason-org/mason.nvim",
    -- otherwise markdown.lua's ensure_installed replaces this list
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        -- Go
        "gopls",
        "gofumpt",
        "goimports",
        "golangci-lint",
        "gotestsum",
        "delve",
        -- Python
        "basedpyright",
        "ruff",
        "debugpy",
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
      },
    },
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
      servers = {
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              analyses = {
                fieldalignment = true,
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                constantValues = true,
                functionTypeParameters = true,
                ignoredError = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
            },
          },
        },
        vtsls = {
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                completion = { enableServerSideFuzzyMatch = true },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = { completeFunctionCalls = true },
              inlayHints = ts_inlay_hints,
            },
            javascript = {
              updateImportsOnFileMove = { enabled = "always" },
              inlayHints = ts_inlay_hints,
            },
          },
          attach = function(client, buf)
            local function map(keys, fn, desc)
              vim.keymap.set("n", keys, fn, { buffer = buf, desc = "TS: " .. desc, silent = true })
            end
            map("gD", function()
              local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
              vtsls_locations(client, "typescript.goToSourceDefinition", { params.textDocument.uri, params.position })
            end, "Goto Source Definition")
            map("gR", function()
              vtsls_locations(client, "typescript.findAllFileReferences", { vim.uri_from_bufnr(buf) })
            end, "File References")
            map("<leader>co", source_action("source.organizeImports"), "Organize Imports")
            map("<leader>cM", source_action("source.addMissingImports.ts"), "Add Missing Imports")
            map("<leader>cu", source_action("source.removeUnused.ts"), "Remove Unused Imports")
            map("<leader>cD", source_action("source.fixAll.ts"), "Fix All Diagnostics")
            map("<leader>cV", function()
              client:exec_cmd(
                { title = "Select TS version", command = "typescript.selectTypeScriptVersion" },
                { bufnr = buf }
              )
            end, "Select TS Workspace Version")
          end,
        },
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",
                autoImportCompletions = true,
                diagnosticMode = "openFilesOnly",
                inlayHints = {
                  variableTypes = true,
                  callArgumentNames = true,
                  functionReturnTypes = true,
                  genericTypes = false,
                },
              },
            },
          },
          on_init = function(client)
            local root = client.root_dir or vim.uv.cwd()
            client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
              python = { pythonPath = require("util.python").python(root) },
            })
            client:notify("workspace/didChangeConfiguration", { settings = nil })
          end,
          attach = function(_, buf)
            vim.keymap.set("n", "<leader>co", source_action("source.organizeImports.ruff"), {
              buffer = buf,
              desc = "Python: Organize Imports",
              silent = true,
            })
          end,
        },
        ruff = {
          init_options = { settings = { logLevel = "error" } },
          attach = function(client)
            client.server_capabilities.hoverProvider = false
          end,
        },
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
              workspace = {
                checkThirdParty = false,
                library = require("config.luarocks").lua_ls_library(),
              },
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
        javascriptreact = { "prettierd", "prettier" },
        typescriptreact = { "prettierd", "prettier" },
        python = { "ruff_organize_imports", "ruff_format" },
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
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        zsh = { "shellcheck" },
      },
      linters = {
        eslint_d = {
          condition = function(ctx)
            return vim.fs.root(ctx.filename, {
              "eslint.config.js",
              "eslint.config.mjs",
              "eslint.config.cjs",
              "eslint.config.ts",
              ".eslintrc",
              ".eslintrc.js",
              ".eslintrc.cjs",
              ".eslintrc.json",
              ".eslintrc.yml",
              ".eslintrc.yaml",
            }) ~= nil
          end,
        },
      },
    },
  },
  -- 5) Debugging
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")

      -- mason-nvim-dap installs js-debug-adapter but ships no adapter
      -- definition for it, so wire pwa-node up by hand.
      local js_debug = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = { js_debug, "${port}" },
        },
      }

      -- Plain `node` only strips types: it can't resolve extensionless imports,
      -- enums or tsconfig paths, so TS files run through tsx instead. Prefer the
      -- project's own tsx (nearest node_modules up the tree), else `npx tsx`.
      local function local_tsx()
        for dir in vim.fs.parents(vim.api.nvim_buf_get_name(0)) do
          local bin = dir .. "/node_modules/.bin/tsx"
          if vim.fn.executable(bin) == 1 then
            return bin
          end
        end
      end

      local skip_files = { "<node_internals>/**", "**/node_modules/**" }

      for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
        local launch = {
          type = "pwa-node",
          request = "launch",
          name = "Launch Current File",
          program = "${file}",
          cwd = "${workspaceFolder}",
          sourceMaps = true,
          skipFiles = skip_files,
        }
        if ft:match("^typescript") then
          launch.runtimeExecutable = function()
            return local_tsx() or "npx"
          end
          launch.runtimeArgs = function()
            return local_tsx() and {} or { "--yes", "tsx" }
          end
        end

        dap.configurations[ft] = {
          launch,
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to Process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
            sourceMaps = true,
          },
        }
      end
    end,
  },
  {
    -- Installs and self-configures debug adapters for the non-Go languages.
    -- Add a language by appending its mason package name to ensure_installed.
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "mason-org/mason.nvim", "mfussenegger/nvim-dap" },
    opts = {
      ensure_installed = { "python", "js", "codelldb", "bash" },
      automatic_installation = true,
      handlers = {
        function(config)
          require("mason-nvim-dap").default_setup(config)
        end,
        -- No-op: nvim-dap-go owns dap.adapters.go (dlv + AWS env passthrough).
        delve = function() end,
        python = function(config)
          local function python()
            return require("util.python").python()
          end
          config.configurations = {
            {
              type = "python",
              request = "launch",
              name = "Python: Launch File",
              program = "${file}",
              cwd = "${workspaceFolder}",
              pythonPath = python,
              console = "integratedTerminal",
              justMyCode = false,
            },
            {
              type = "python",
              request = "launch",
              name = "Python: Launch File (args)",
              program = "${file}",
              cwd = "${workspaceFolder}",
              pythonPath = python,
              args = function()
                return vim.split(vim.fn.input("Args: "), " +", { trimempty = true })
              end,
              console = "integratedTerminal",
              justMyCode = false,
            },
            {
              type = "python",
              request = "launch",
              name = "Python: Launch Module",
              module = function()
                return vim.fn.input("Module: ")
              end,
              cwd = "${workspaceFolder}",
              pythonPath = python,
              console = "integratedTerminal",
              justMyCode = false,
            },
            {
              type = "python",
              request = "attach",
              name = "Python: Attach (debugpy :5678)",
              connect = { host = "127.0.0.1", port = 5678 },
              justMyCode = false,
            },
          }
          require("mason-nvim-dap").default_setup(config)
        end,
      },
    },
  },
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
