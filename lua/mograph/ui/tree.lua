local manager = require("mograph.connection.manager")
local float = require("mograph.ui.float")

local M = {}

local function format_entry(loc, index, total, current_bufnr, current_line)
  local prefix = index == total and "└─ " or "├─ "
  local resolved_line = manager.resolve_location(loc)

  if not resolved_line then
    return prefix .. string.format("⚠ %s  (location not found)", loc.file)
  end

  local label = string.format("%s:%d", loc.file, resolved_line)

  if current_bufnr and current_line then
    local abs_current = vim.api.nvim_buf_get_name(current_bufnr)
    local abs_loc = vim.fn.fnamemodify(manager.root() .. "/" .. loc.file, ":p")
    if abs_current == abs_loc and resolved_line == current_line then
      label = label .. "     ← current"
    end
  end

  return prefix .. label
end

--- Show every location within a single connection.
function M.show_connection(conn_name)
  local conn = manager.get_connection(conn_name)
  if not conn then
    vim.notify("mograph: connection '" .. conn_name .. "' not found", vim.log.levels.WARN)
    return
  end

  local current_bufnr = vim.api.nvim_get_current_buf()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]

  local items = {}
  for i, loc in ipairs(conn.locations) do
    local display = format_entry(loc, i, #conn.locations, current_bufnr, current_line)
    table.insert(items, { display = display, value = loc })
  end

  float.show_list(conn_name, items, function(loc)
    require("mograph.navigation").jump_to_location(loc)
  end)
end

--- Show every connection that passes through the current line, each with
--- its full list of member locations (the `<leader>cl` view).
function M.show_connections_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1]

  local hits = manager.get_connections_at(bufnr, line)
  if #hits == 0 then
    vim.notify("mograph: no connections at this line", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, hit in ipairs(hits) do
    local conn = manager.get_connection(hit.connection)
    table.insert(items, { display = "󰌷 " .. hit.connection, value = { kind = "connection", name = hit.connection } })
    for i, loc in ipairs(conn.locations) do
      local entry_line = "   " .. format_entry(loc, i, #conn.locations, bufnr, line)
      table.insert(items, { display = entry_line, value = { kind = "location", location = loc } })
    end
  end

  float.show_list("Connections", items, function(value)
    if value.kind == "location" then
      require("mograph.navigation").jump_to_location(value.location)
    else
      M.show_connection(value.name)
    end
  end)
end

return M
