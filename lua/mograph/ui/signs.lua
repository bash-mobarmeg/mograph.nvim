local manager = require("mograph.connection.manager")

local M = {}

local SIGN_GROUP = "mograph"
local SIGN_SINGLE = "MographSingle"
local SIGN_MULTI = "MographMulti"

local defined = false

local function define_signs(config)
  if defined then
    return
  end
  vim.fn.sign_define(SIGN_SINGLE, {
    text = config.signs.single,
    texthl = config.signs.sign_hl,
  })
  vim.fn.sign_define(SIGN_MULTI, {
    text = config.signs.multiple,
    texthl = config.signs.sign_hl_multi,
  })
  defined = true
end

function M.setup(config)
  if config.signs.enabled then
    define_signs(config)
  end
end

function M.clear_buffer(bufnr)
  vim.fn.sign_unplace(SIGN_GROUP, { buffer = bufnr })
end

--- Recompute and redraw signs for a single buffer.
function M.refresh_buffer(bufnr)
  local config = manager.state.config
  if not config or not config.signs.enabled then
    return
  end
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_buf_get_name(bufnr) == "" then
    return
  end

  M.clear_buffer(bufnr)

  local by_line = manager.get_line_map_for_buffer(bufnr)
  for line, entries in pairs(by_line) do
    local name = #entries > 1 and SIGN_MULTI or SIGN_SINGLE
    vim.fn.sign_place(0, SIGN_GROUP, name, bufnr, { lnum = line, priority = 20 })
  end
end

--- Refresh signs in every currently loaded, listed buffer.
function M.refresh_all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      M.refresh_buffer(bufnr)
    end
  end
end

return M
