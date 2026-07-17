local M = {}

-- bufnr -> stack of { node = TSNode, range = { srow, scol, erow, ecol } }
local selections = {}

local function in_visual_mode()
  local mode = vim.fn.mode()
  return mode == "v" or mode == "V" or mode == "\22"
end

local function select_range(srow, scol, erow, ecol)
  if in_visual_mode() then
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, "x", false)
  end
  vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
  vim.cmd("normal! v")
  if ecol == 0 then
    erow = erow - 1
    ecol = math.max(vim.fn.col({ erow + 1, "$" }) - 1, 0)
  else
    ecol = ecol - 1
  end
  vim.api.nvim_win_set_cursor(0, { erow + 1, ecol })
end

function M.grow()
  local bufnr = vim.api.nvim_get_current_buf()
  local stack = selections[bufnr]

  if in_visual_mode() and stack and #stack > 0 then
    local parent = stack[#stack].node:parent()
    if not parent then
      return
    end
    local srow, scol, erow, ecol = parent:range()
    table.insert(stack, { node = parent, range = { srow, scol, erow, ecol } })
    select_range(srow, scol, erow, ecol)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local node = vim.treesitter.get_node({ pos = { cursor[1] - 1, cursor[2] } })
  if not node then
    return
  end
  local srow, scol, erow, ecol = node:range()
  selections[bufnr] = { { node = node, range = { srow, scol, erow, ecol } } }
  select_range(srow, scol, erow, ecol)
end

function M.shrink()
  local bufnr = vim.api.nvim_get_current_buf()
  local stack = selections[bufnr]
  if not stack or #stack < 2 then
    local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(esc, "x", false)
    selections[bufnr] = nil
    return
  end
  table.remove(stack)
  local range = stack[#stack].range
  select_range(range[1], range[2], range[3], range[4])
end

return M
