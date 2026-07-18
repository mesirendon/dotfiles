-- LSP glue that used to come from LazyVim: on-attach keymaps (capability-gated),
-- diagnostics config, inlay hints, and blink.cmp capabilities. Consumed by
-- `plugins/lsp.lua`.

local M = {}

local icons = require("config.icons").icons

---@type vim.diagnostic.Opts
M.diagnostics = {
  underline = true,
  update_in_insert = false,
  virtual_text = {
    spacing = 4,
    source = "if_many",
    prefix = "●",
  },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
      [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
      [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
      [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
    },
  },
}

-- Merge blink.cmp's capabilities into the LSP defaults so completion works.
function M.capabilities()
  local caps = vim.lsp.protocol.make_client_capabilities()
  local ok, blink = pcall(require, "blink.cmp")
  if ok then
    caps = blink.get_lsp_capabilities(caps)
  end
  caps = vim.tbl_deep_extend("force", caps, {
    workspace = {
      fileOperations = { didRename = true, willRename = true },
    },
  })
  return caps
end

-- Buffer-local keymaps, set on LspAttach and gated by server capabilities.
---@param client vim.lsp.Client
---@param buf integer
function M.on_attach(client, buf)
  local function has(method)
    method = method:find("/") and method or ("textDocument/" .. method)
    return client:supports_method(method, buf)
  end

  local function map(keys, fn, desc, mode)
    vim.keymap.set(mode or "n", keys, fn, { buffer = buf, desc = "LSP: " .. desc, silent = true })
  end

  map("<leader>cl", function()
    Snacks.picker.lsp_config()
  end, "Lsp Info")

  if has("definition") then
    map("gd", function()
      Snacks.picker.lsp_definitions()
    end, "Goto Definition")
  end
  if has("references") then
    map("gr", function()
      Snacks.picker.lsp_references()
    end, "References")
  end
  if has("implementation") then
    map("gI", function()
      Snacks.picker.lsp_implementations()
    end, "Goto Implementation")
  end
  if has("typeDefinition") then
    map("gy", function()
      Snacks.picker.lsp_type_definitions()
    end, "Goto Type Definition")
  end
  map("gD", vim.lsp.buf.declaration, "Goto Declaration")
  map("K", function()
    return vim.lsp.buf.hover()
  end, "Hover")

  if has("signatureHelp") then
    map("gK", function()
      return vim.lsp.buf.signature_help()
    end, "Signature Help")
    map("<c-k>", function()
      return vim.lsp.buf.signature_help()
    end, "Signature Help", "i")
  end
  if has("codeAction") then
    map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "x" })
    map("<leader>cA", function()
      vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
    end, "Source Action")
  end
  if has("codeLens") then
    map("<leader>cc", vim.lsp.codelens.run, "Run Codelens", { "n", "x" })
    map("<leader>cC", vim.lsp.codelens.refresh, "Refresh & Display Codelens")
  end
  if has("rename") then
    map("<leader>cr", vim.lsp.buf.rename, "Rename")
  end
  map("<leader>cR", function()
    Snacks.rename.rename_file()
  end, "Rename File")

  if has("documentSymbol") then
    map("<leader>ss", function()
      Snacks.picker.lsp_symbols({ filter = require("config.icons").kind_filter })
    end, "LSP Symbols")
  end
  map("<leader>sS", function()
    Snacks.picker.lsp_workspace_symbols({ filter = require("config.icons").kind_filter })
  end, "LSP Workspace Symbols")

  if has("callHierarchy/incomingCalls") then
    map("gai", function()
      Snacks.picker.lsp_incoming_calls()
    end, "Calls Incoming")
  end
  if has("callHierarchy/outgoingCalls") then
    map("gao", function()
      Snacks.picker.lsp_outgoing_calls()
    end, "Calls Outgoing")
  end

  if has("documentHighlight") then
    map("]]", function()
      Snacks.words.jump(vim.v.count1)
    end, "Next Reference")
    map("[[", function()
      Snacks.words.jump(-vim.v.count1)
    end, "Prev Reference")
    map("<a-n>", function()
      Snacks.words.jump(vim.v.count1, true)
    end, "Next Reference")
    map("<a-p>", function()
      Snacks.words.jump(-vim.v.count1, true)
    end, "Prev Reference")
  end

  -- inlay hints
  if has("inlayHint") and vim.bo[buf].buftype == "" then
    vim.lsp.inlay_hint.enable(true, { bufnr = buf })
  end
end

function M.setup()
  vim.diagnostic.config(vim.deepcopy(M.diagnostics))

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("config_lsp_attach", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        M.on_attach(client, args.buf)
      end
    end,
  })
end

return M
