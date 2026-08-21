local manager = require("mograph.connection.manager")

local M = {}

--- Prompt for a connection name (used for create).
function M.input_connection_name(callback)
  vim.ui.input({ prompt = "Connection name: " }, function(input)
    if input == nil then
      return
    end
    callback(input)
  end)
end

--- Let the user pick an existing connection name.
function M.select_connection(callback, opts)
  opts = opts or {}
  local names = manager.get_connection_names()
  if #names == 0 then
    vim.notify("mograph: no connections exist yet", vim.log.levels.INFO)
    return
  end
  vim.ui.select(names, { prompt = opts.prompt or "Select connection:" }, function(choice)
    if choice then
      callback(choice)
    end
  end)
end

--- Let the user pick from an arbitrary list of { label, value }.
function M.select(items, prompt, callback)
  local labels = {}
  for _, item in ipairs(items) do
    table.insert(labels, item.label)
  end
  vim.ui.select(labels, { prompt = prompt }, function(choice, idx)
    if choice and idx then
      callback(items[idx].value)
    end
  end)
end

function M.confirm(prompt, callback)
  vim.ui.select({ "Yes", "No" }, { prompt = prompt }, function(choice)
    callback(choice == "Yes")
  end)
end

return M
