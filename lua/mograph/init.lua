local config = require("mograph.config")
local manager = require("mograph.connection.manager")
local commands = require("mograph.commands")
local keymaps = require("mograph.keymaps")
local signs = require("mograph.ui.signs")

local M = {}

M._initialized = false

function M.setup(opts)
  local cfg = config.setup(opts)

  manager.setup(cfg)
  signs.setup(cfg)
  commands.register()
  keymaps.register(cfg)

  local group = vim.api.nvim_create_augroup("MographAutocmds", { clear = true })

  -- Recompute signs whenever a connected buffer becomes visible.
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = group,
    callback = function(args)
      signs.refresh_buffer(args.buf)
    end,
  })

  -- Keep signs (and their backing extmarks) accurate as lines move.
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
    group = group,
    callback = function(args)
      signs.refresh_buffer(args.buf)
    end,
  })

  M._initialized = true
end

-- Public Lua API re-exports so users can build their own keymaps/commands.
M.create_connection = commands.create
M.add_location = commands.add
M.show_connections_at_cursor = commands.list_current
M.show_all_connections = commands.list_all
M.remove_location = commands.remove
M.delete_connection = commands.delete
M.next_location = commands.next
M.previous_location = commands.previous
M.refresh = commands.refresh

return M
