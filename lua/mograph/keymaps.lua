local commands = require("mograph.commands")

local M = {}

function M.register(config)
  if not config.keymaps.enabled then
    return
  end

  local km = config.keymaps
  local function map(lhs, fn, desc)
    if not lhs then
      return
    end
    vim.keymap.set("n", lhs, fn, { desc = "mograph: " .. desc, silent = true })
  end

  map(km.create, commands.create, "create connection")
  map(km.add, commands.add, "add line to connection")
  map(km.list_current, commands.list_current, "show connections at line")
  map(km.list_all, commands.list_all, "show all connections")
  map(km.remove, commands.remove, "remove line from connection")
  map(km.next, commands.next, "next connected location")
  map(km.previous, commands.previous, "previous connected location")
end

return M
