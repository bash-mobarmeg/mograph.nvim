local utils = require("mograph.utils")

local M = {}

M.ns = vim.api.nvim_create_namespace("mograph")

-- marks[bufnr][location_id] = extmark_id
local marks = {}

function M.clear_buffer(bufnr)
  if marks[bufnr] then
    pcall(vim.api.nvim_buf_clear_namespace, bufnr, M.ns, 0, -1)
    marks[bufnr] = nil
  end
end

local function set_mark(bufnr, location, line)
  marks[bufnr] = marks[bufnr] or {}
  local row = line - 1

  local existing = marks[bufnr][location.id]
  if existing then
    pcall(vim.api.nvim_buf_del_extmark, bufnr, M.ns, existing)
  end

  local ok, id = pcall(vim.api.nvim_buf_set_extmark, bufnr, M.ns, row, 0, {})
  if ok then
    marks[bufnr][location.id] = id
    return id
  end
  return nil
end

local function get_mark_line(bufnr, location)
  if not marks[bufnr] or not marks[bufnr][location.id] then
    return nil
  end
  local ok, pos = pcall(vim.api.nvim_buf_get_extmark_by_id, bufnr, M.ns, marks[bufnr][location.id], {})
  if not ok or not pos or #pos == 0 then
    return nil
  end
  return pos[1] + 1
end

--- Search the buffer for a line whose text matches location.text, radiating
--- outward from the stored line number first (cheap for small edits), then
--- falling back to a full scan.
local function search_by_text(bufnr, location)
  if not location.text or utils.trim(location.text) == "" then
    return nil
  end

  local total = vim.api.nvim_buf_line_count(bufnr)
  local target = utils.trim(location.text)
  local start_line = math.min(math.max(location.line, 1), total)
  local radius = 200

  for offset = 0, radius do
    for _, l in ipairs({ start_line - offset, start_line + offset }) do
      if l >= 1 and l <= total then
        local text = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
        if utils.trim(text) == target then
          return l
        end
      end
    end
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, text in ipairs(lines) do
    if utils.trim(text) == target then
      return i
    end
  end

  return nil
end

--- Search the buffer for a line mentioning the stored symbol name.
local function search_by_symbol(bufnr, location)
  if not location.symbol or location.symbol == "" then
    return nil
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, text in ipairs(lines) do
    if text:find(location.symbol, 1, true) then
      return i
    end
  end
  return nil
end

--- Resolve a location to a current 1-indexed line number in `bufnr`.
--- Resolution order: live extmark -> stored line (verified) -> text search
--- -> symbol search -> unresolved (nil).
function M.resolve(bufnr, location)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    -- Can't verify text without a loaded buffer; trust the stored line.
    return location.line, "line"
  end

  local mark_line = get_mark_line(bufnr, location)
  if mark_line then
    local text = vim.api.nvim_buf_get_lines(bufnr, mark_line - 1, mark_line, false)[1]
    if text and (not location.text or utils.trim(text) == utils.trim(location.text)) then
      return mark_line, "extmark"
    end
  end

  local total = vim.api.nvim_buf_line_count(bufnr)
  if location.line >= 1 and location.line <= total then
    local text = vim.api.nvim_buf_get_lines(bufnr, location.line - 1, location.line, false)[1] or ""
    if not location.text or utils.trim(text) == utils.trim(location.text) then
      set_mark(bufnr, location, location.line)
      return location.line, "line"
    end
  end

  local found = search_by_text(bufnr, location)
  if found then
    set_mark(bufnr, location, found)
    return found, "text"
  end

  found = search_by_symbol(bufnr, location)
  if found then
    set_mark(bufnr, location, found)
    return found, "symbol"
  end

  return nil, nil
end

--- Establish extmark tracking for a freshly created/added location, while
--- the buffer is loaded and its line is known-good.
function M.track(bufnr, location)
  set_mark(bufnr, location, location.line)
end

return M
