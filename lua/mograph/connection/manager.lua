local storage = require("mograph.connection.storage")
local model = require("mograph.connection.model")
local resolver = require("mograph.connection.resolver")
local utils = require("mograph.utils")

local M = {}

M.state = {
  config = nil,
  root = nil,
  data = nil,
}

function M.setup(config)
  M.state.config = config
  M.state.root = utils.find_workspace_root(config.workspace_markers)
  M.state.data = storage.load(config, M.state.root)
end

function M.root()
  return M.state.root
end

local function save()
  storage.save(M.state.config, M.state.root, M.state.data)
end
M.save = save

function M.get_connection_names()
  local names = {}
  for name, _ in pairs(M.state.data.connections) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

function M.get_connection(name)
  return M.state.data.connections[name]
end

function M.connection_exists(name)
  return M.state.data.connections[name] ~= nil
end

--- Create a connection (if missing) and add the current cursor location.
--- Returns conn, err, location.
function M.create_connection(name, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  name = utils.trim(name)
  if name == "" then
    return nil, "connection name cannot be empty"
  end

  if not M.state.data.connections[name] then
    M.state.data.connections[name] = model.new_connection()
  end

  local conn = M.state.data.connections[name]
  local location = model.new_location(bufnr, M.state.root)

  for _, existing in ipairs(conn.locations) do
    if model.same_place(existing, location) then
      resolver.track(bufnr, existing)
      return conn, nil, existing
    end
  end

  table.insert(conn.locations, location)
  resolver.track(bufnr, location)
  save()
  return conn, nil, location
end

--- Add the current cursor location to an existing connection by name.
--- Returns conn, err, location.
function M.add_location(name, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local conn = M.state.data.connections[name]
  if not conn then
    return nil, "connection '" .. name .. "' does not exist"
  end

  local location = model.new_location(bufnr, M.state.root)

  for _, existing in ipairs(conn.locations) do
    if model.same_place(existing, location) then
      resolver.track(bufnr, existing)
      return conn, nil, existing
    end
  end

  table.insert(conn.locations, location)
  resolver.track(bufnr, location)
  save()
  return conn, nil, location
end

--- Remove a single location (by id) from a connection. The connection is
--- deleted entirely if it becomes empty.
function M.remove_location(conn_name, location_id)
  local conn = M.state.data.connections[conn_name]
  if not conn then
    return false, "connection '" .. conn_name .. "' does not exist"
  end

  for i, loc in ipairs(conn.locations) do
    if loc.id == location_id then
      table.remove(conn.locations, i)
      break
    end
  end

  if #conn.locations == 0 then
    M.state.data.connections[conn_name] = nil
  end

  save()
  return true
end

function M.delete_connection(conn_name)
  if not M.state.data.connections[conn_name] then
    return false, "connection '" .. conn_name .. "' does not exist"
  end
  M.state.data.connections[conn_name] = nil
  save()
  return true
end

--- Resolve a location for display/navigation. Returns resolved 1-indexed
--- line (or nil if unresolved), a status string, and the buffer number
--- used to resolve it.
function M.resolve_location(location)
  local abs = utils.to_absolute(location.file, M.state.root)
  local bufnr = vim.fn.bufnr(abs)

  if bufnr == -1 or not vim.api.nvim_buf_is_loaded(bufnr) then
    if vim.fn.filereadable(abs) == 0 then
      return nil, nil, bufnr
    end
    bufnr = vim.fn.bufadd(abs)
    vim.fn.bufload(bufnr)
  end

  local line, status = resolver.resolve(bufnr, location)
  return line, status, bufnr
end

--- Every connection/location pair whose resolved location matches the
--- given buffer+line (the "current" line).
function M.get_connections_at(bufnr, line)
  local abs = vim.api.nvim_buf_get_name(bufnr)
  local rel = utils.to_relative(abs, M.state.root)

  local results = {}
  for name, conn in pairs(M.state.data.connections) do
    for _, loc in ipairs(conn.locations) do
      if loc.file == rel then
        local resolved_line = resolver.resolve(bufnr, loc)
        if resolved_line == line then
          table.insert(results, { connection = name, location = loc })
        end
      end
    end
  end

  table.sort(results, function(a, b)
    return a.connection < b.connection
  end)

  return results
end

--- Map of resolved line -> { {connection=, location=}, ... } for sign
--- placement in a given buffer.
function M.get_line_map_for_buffer(bufnr)
  local abs = vim.api.nvim_buf_get_name(bufnr)
  if abs == "" then
    return {}
  end
  local rel = utils.to_relative(abs, M.state.root)

  local by_line = {}
  for name, conn in pairs(M.state.data.connections) do
    for _, loc in ipairs(conn.locations) do
      if loc.file == rel then
        local resolved_line = resolver.resolve(bufnr, loc)
        if resolved_line then
          by_line[resolved_line] = by_line[resolved_line] or {}
          table.insert(by_line[resolved_line], { connection = name, location = loc })
        end
      end
    end
  end

  return by_line
end

--- Flattened, sorted list of every location in the workspace, each
--- annotated with its connection name. Used for cross-file navigation.
function M.get_all_locations_flat()
  local all = {}
  for name, conn in pairs(M.state.data.connections) do
    for _, loc in ipairs(conn.locations) do
      table.insert(all, { connection = name, location = loc })
    end
  end

  table.sort(all, function(a, b)
    if a.location.file == b.location.file then
      return a.location.line < b.location.line
    end
    return a.location.file < b.location.file
  end)

  return all
end

return M
