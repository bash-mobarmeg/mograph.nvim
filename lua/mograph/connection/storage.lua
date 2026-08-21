local M = {}

local function json_encode(data)
  if vim.json and vim.json.encode then
    return vim.json.encode(data)
  end
  return vim.fn.json_encode(data)
end

local function json_decode(str)
  if vim.json and vim.json.decode then
    return vim.json.decode(str)
  end
  return vim.fn.json_decode(str)
end

function M.path(config, root)
  if config.storage.mode == "global" then
    return vim.fn.expand(config.storage.global_path)
  end
  return root .. "/" .. config.data_dir .. "/" .. config.data_file
end

local function default_data()
  return { version = 1, connections = {} }
end

--- Load the connection graph from disk, returning a fresh default table if
--- the file does not exist yet or fails to parse.
function M.load(config, root)
  local path = M.path(config, root)
  if vim.fn.filereadable(path) == 0 then
    return default_data()
  end

  local lines = vim.fn.readfile(path)
  local content = table.concat(lines, "\n")
  if content == "" then
    return default_data()
  end

  local ok, data = pcall(json_decode, content)
  if not ok or type(data) ~= "table" then
    vim.notify("mograph: failed to parse " .. path .. ", starting fresh", vim.log.levels.WARN)
    return default_data()
  end

  data.connections = data.connections or {}
  data.version = data.version or 1
  return data
end

--- Persist the connection graph to disk, creating the data directory if
--- necessary.
function M.save(config, root, data)
  local path = M.path(config, root)
  local dir = vim.fn.fnamemodify(path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end

  local ok, encoded = pcall(json_encode, data)
  if not ok then
    vim.notify("mograph: failed to encode connection data", vim.log.levels.ERROR)
    return false
  end

  local ok2, err = pcall(vim.fn.writefile, { encoded }, path)
  if not ok2 then
    vim.notify("mograph: failed to save " .. path .. ": " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  return true
end

return M
