local manager = require("mograph.connection.manager")
local picker = require("mograph.ui.picker")
local tree = require("mograph.ui.tree")
local navigation = require("mograph.navigation")
local signs = require("mograph.ui.signs")

local M = {}

local function refresh_current()
  signs.refresh_buffer(vim.api.nvim_get_current_buf())
end

function M.create()
  picker.input_connection_name(function(name)
    local conn, err, location = manager.create_connection(name)
    if err then
      vim.notify("mograph: " .. err, vim.log.levels.ERROR)
      return
    end
    vim.notify("mograph: added to '" .. name .. "' (" .. location.file .. ":" .. location.line .. ")")
    refresh_current()
  end)
end

function M.add()
  if #manager.get_connection_names() == 0 then
    vim.notify("mograph: no connections exist yet, create one first", vim.log.levels.INFO)
    return
  end
  picker.select_connection(function(name)
    local conn, err, location = manager.add_location(name)
    if err then
      vim.notify("mograph: " .. err, vim.log.levels.ERROR)
      return
    end
    vim.notify("mograph: added to '" .. name .. "' (" .. location.file .. ":" .. location.line .. ")")
    refresh_current()
  end, { prompt = "Add current line to:" })
end

function M.list_current()
  tree.show_connections_at_cursor()
end

function M.list_all()
  local names = manager.get_connection_names()
  if #names == 0 then
    vim.notify("mograph: no connections yet", vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, name in ipairs(names) do
    local conn = manager.get_connection(name)
    table.insert(items, { display = string.format("%s (%d)", name, #conn.locations), value = name })
  end
  require("mograph.ui.float").show_list("Connections", items, function(name)
    tree.show_connection(name)
  end)
end

function M.remove()
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local hits = manager.get_connections_at(bufnr, line)

  if #hits == 0 then
    vim.notify("mograph: current line is not part of any connection", vim.log.levels.INFO)
    return
  end

  local function do_remove(hit)
    picker.confirm("Remove this location from '" .. hit.connection .. "'?", function(ok)
      if not ok then
        return
      end
      manager.remove_location(hit.connection, hit.location.id)
      vim.notify("mograph: removed from '" .. hit.connection .. "'")
      refresh_current()
    end)
  end

  if #hits == 1 then
    do_remove(hits[1])
    return
  end

  local items = {}
  for _, hit in ipairs(hits) do
    table.insert(items, { label = hit.connection, value = hit })
  end
  picker.select(items, "Remove current line from which connection?", do_remove)
end

function M.delete()
  picker.select_connection(function(name)
    picker.confirm("Delete entire connection '" .. name .. "'? This removes all its locations.", function(ok)
      if not ok then
        return
      end
      manager.delete_connection(name)
      vim.notify("mograph: deleted '" .. name .. "'")
      signs.refresh_all()
    end)
  end, { prompt = "Delete which connection?" })
end

function M.next()
  navigation.next()
end

function M.previous()
  navigation.previous()
end

function M.refresh()
  signs.refresh_all()
  vim.notify("mograph: refreshed")
end

function M.register()
  local function cmd(name, fn, desc)
    vim.api.nvim_create_user_command(name, fn, { desc = desc })
  end

  cmd("MoGraphCreate", M.create, "Create a connection from the current line")
  cmd("MoGraphAdd", M.add, "Add the current line to an existing connection")
  cmd("MoGraphList", M.list_current, "Show connections at the current line")
  cmd("MoGraphConnections", M.list_all, "List every connection in the workspace")
  cmd("MoGraph", M.list_all, "List every connection in the workspace")
  cmd("MoGraphRemove", M.remove, "Remove the current line from a connection")
  cmd("MoGraphDelete", M.delete, "Delete an entire connection")
  cmd("MoGraphNext", M.next, "Jump to the next connected location")
  cmd("MoGraphPrevious", M.previous, "Jump to the previous connected location")
  cmd("MoGraphRefresh", M.refresh, "Recompute signs for all buffers")
end

return M
