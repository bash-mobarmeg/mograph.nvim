local utils = require("mograph.utils")

local M = {}

--- Build a new location table from the current cursor position in `bufnr`.
--- `to_storage_path(abs_path)` converts the buffer's absolute path into
--- whatever form the manager stores (absolute for global mode, relative to
--- a workspace root for workspace mode).
function M.new_location(bufnr, to_storage_path)
  bufnr = bufnr or 0
  local win = vim.fn.bufwinid(bufnr)
  local cursor = win ~= -1 and vim.api.nvim_win_get_cursor(win) or { vim.fn.line("."), 0 }
  local line = cursor[1]

  local abs_path = vim.api.nvim_buf_get_name(bufnr)
  local file_path = to_storage_path(abs_path)

  local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ""
  local symbol = utils.get_symbol_at(bufnr, line)

  return {
    id = utils.generate_id(),
    file = file_path,
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
