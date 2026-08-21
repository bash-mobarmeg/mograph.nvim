local utils = require("mograph.utils")

local M = {}

--- Build a new location table from the current cursor position in `bufnr`.
function M.new_location(bufnr, root)
  bufnr = bufnr or 0
  local win = vim.fn.bufwinid(bufnr)
  local cursor = win ~= -1 and vim.api.nvim_win_get_cursor(win) or { vim.fn.line("."), 0 }
  local line = cursor[1]

  local abs_path = vim.api.nvim_buf_get_name(bufnr)
  local rel_path = utils.to_relative(abs_path, root)

  local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ""
  local symbol = utils.get_symbol_at(bufnr, line)

  return {
    id = utils.generate_id(),
    file = rel_path,
    line = line,
    text = text,
    symbol = symbol,
  }
end

--- True if two locations point at the same file+line.
function M.same_place(a, b)
  return a.file == b.file and a.line == b.line
end

--- A new, empty connection.
function M.new_connection()
  return { locations = {} }
end

return M
