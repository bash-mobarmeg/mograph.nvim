local M = {}

local function create_win(lines, opts)
  opts = opts or {}
  local width = opts.width or 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(math.max(width + 4, 30), math.floor(vim.o.columns * 0.8))
  local height = math.min(math.max(#lines, 1) + 2, math.floor(vim.o.lines * 0.6))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "mograph"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = opts.border or "rounded",
    title = opts.title,
    title_pos = opts.title and "center" or nil,
  })

  return buf, win
end

--- Show a simple selectable list.
--- items: array of { display = string, value = any }
--- on_select(value) is called when the user presses <CR> on an item.
function M.show_list(title, items, on_select)
  if #items == 0 then
    vim.notify("mograph: nothing to show", vim.log.levels.INFO)
    return
  end

  local lines = {}
  for _, item in ipairs(items) do
    table.insert(lines, item.display)
  end

  local buf, win = create_win(lines, { title = title })

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function select()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local item = items[row]
    close()
    if item and item.value ~= nil and on_select then
      on_select(item.value)
    end
  end

  local map_opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<CR>", select, map_opts)
  vim.keymap.set("n", "q", close, map_opts)
  vim.keymap.set("n", "<Esc>", close, map_opts)
end

--- Show a read-only informational panel (no selection).
function M.show_info(title, lines)
  local buf, win = create_win(lines, { title = title })
  local map_opts = { buffer = buf, nowait = true, silent = true }
  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set("n", "q", close, map_opts)
  vim.keymap.set("n", "<Esc>", close, map_opts)
end

return M
