local M = {}

--- Generate a short, sufficiently-unique id for a location.
function M.generate_id()
  return string.format("%x-%x", os.time(), math.random(0, 0xffffff))
end

--- Find the workspace root by walking up from `start_path` looking for
--- marker files/directories such as .mograph or .git.
function M.find_workspace_root(markers, start_path)
  markers = markers or { ".mograph", ".git" }
  start_path = start_path or vim.fn.getcwd()

  local path = vim.fn.fnamemodify(start_path, ":p"):gsub("/$", "")

  while path ~= "" and path ~= "/" do
    for _, marker in ipairs(markers) do
      local candidate = path .. "/" .. marker
      if vim.fn.isdirectory(candidate) == 1 or vim.fn.filereadable(candidate) == 1 then
        return path
      end
    end
    local parent = vim.fn.fnamemodify(path, ":h")
    if parent == path then
      break
    end
    path = parent
  end

  return vim.fn.getcwd()
end

--- Normalize an absolute path to be relative to the workspace root.
function M.to_relative(abs_path, root)
  abs_path = vim.fn.fnamemodify(abs_path, ":p")
  root = vim.fn.fnamemodify(root, ":p"):gsub("/$", "")
  if abs_path:sub(1, #root) == root then
    return abs_path:sub(#root + 2)
  end
  return abs_path
end

--- Turn a workspace-relative path into an absolute path.
function M.to_absolute(rel_path, root)
  if vim.fn.fnamemodify(rel_path, ":p") == rel_path then
    return rel_path
  end
  return root .. "/" .. rel_path
end

--- Best-effort symbol/function name detection at or above `line`.
--- Prefers treesitter when a parser is available, otherwise falls back to
--- a small regex heuristic that covers common JS/TS/Python/Go/Lua shapes.
function M.get_symbol_at(bufnr, line)
  bufnr = bufnr or 0
  line = line or vim.api.nvim_win_get_cursor(0)[1]

  local ok_ts, ts_symbol = pcall(M._get_symbol_treesitter, bufnr, line)
  if ok_ts and ts_symbol then
    return ts_symbol
  end

  return M._get_symbol_regex(bufnr, line)
end

function M._get_symbol_treesitter(bufnr, line)
  local ok_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok_parsers or not parsers.has_parser() then
    return nil
  end

  local ts = vim.treesitter
  local ok_parser, parser = pcall(ts.get_parser, bufnr)
  if not ok_parser or not parser then
    return nil
  end

  local tree = parser:parse()[1]
  if not tree then
    return nil
  end

  local root = tree:root()
  local row = line - 1
  local node = root:named_descendant_for_range(row, 0, row, 0)

  while node do
    local ntype = node:type()
    if ntype:match("function") or ntype:match("method") then
      for i = 0, node:named_child_count() - 1 do
        local child = node:named_child(i)
        if child and child:type() == "identifier" then
          return ts.get_node_text(child, bufnr)
        end
      end
    end
    node = node:parent()
  end

  return nil
end

--- Regex-based heuristic: scan upward from `line` for common declaration
--- patterns.
function M._get_symbol_regex(bufnr, line)
  local patterns = {
    "function%s+([%w_]+)",
    "const%s+([%w_]+)%s*=",
    "let%s+([%w_]+)%s*=",
    "class%s+([%w_]+)",
    "def%s+([%w_]+)",
    "func%s+([%w_]+)",
    "([%w_]+)%s*%(.-%)%s*{",
  }

  local max_up = 15

  for offset = 0, max_up do
    local l = line - offset
    if l < 1 then
      break
    end
    local text = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
    for _, pat in ipairs(patterns) do
      local m = text:match(pat)
      if m then
        return m
      end
    end
  end

  return nil
end

--- Trim leading/trailing whitespace.
function M.trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

return M
