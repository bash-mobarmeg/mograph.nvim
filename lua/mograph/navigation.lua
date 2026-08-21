local manager = require("mograph.connection.manager")

local M = {}

--- Open the given location's file and move the cursor to its resolved line.
function M.jump_to_location(location)
  local line = manager.resolve_location(location)

  local abs = manager.to_absolute_path(location.file)
  if vim.fn.filereadable(abs) == 0 then
    vim.notify("mograph: file not found: " .. location.file, vim.log.levels.ERROR)
    return
  end

  vim.cmd("edit " .. vim.fn.fnameescape(abs))

  local target = line or location.line
  local total = vim.api.nvim_buf_line_count(0)
  target = math.min(math.max(target, 1), total)

  vim.api.nvim_win_set_cursor(0, { target, 0 })
  vim.cmd("normal! zz")

  if not line then
    vim.notify(
      "mograph: '" .. location.file .. "' location could not be precisely resolved; jumped to last known line",
      vim.log.levels.WARN
    )
  end
end

local function current_position()
  local bufnr = vim.api.nvim_get_current_buf()
  local abs = vim.api.nvim_buf_get_name(bufnr)
  local key = manager.to_storage_path(abs)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  return key, line
end

--- Move to the next (or, if `backwards`, previous) connected location in
--- the workspace, ordered by file then line, wrapping at the ends.
local function step(backwards)
  local all = manager.get_all_locations_flat()
  if #all == 0 then
    vim.notify("mograph: no connections in workspace", vim.log.levels.INFO)
    return
  end

  local key, line = current_position()

  local function is_after(entry)
    if entry.location.file ~= key then
      return entry.location.file > key
    end
    return entry.location.line > line
  end

  local function is_before(entry)
    if entry.location.file ~= key then
      return entry.location.file < key
    end
    return entry.location.line < line
  end

  if backwards then
    for i = #all, 1, -1 do
      if is_before(all[i]) then
        M.jump_to_location(all[i].location)
        return
      end
    end
    M.jump_to_location(all[#all].location)
  else
    for _, entry in ipairs(all) do
      if is_after(entry) then
        M.jump_to_location(entry.location)
        return
      end
    end
    M.jump_to_location(all[1].location)
  end
end

function M.next()
  step(false)
end

function M.previous()
  step(true)
end

return M
