local M = {}

M.defaults = {
  data_dir = ".mograph",
  data_file = "connections.json",

  workspace_markers = { ".mograph", ".git" },

  signs = {
    enabled = true,
    single = "●",
    multiple = "◆",
    unresolved = "⚠",
    sign_hl = "DiagnosticInfo",
    sign_hl_multi = "DiagnosticWarn",
    sign_hl_unresolved = "DiagnosticError",
  },

  keymaps = {
    enabled = true,
    create = "<leader>mc",
    add = "<leader>ma",
    list_current = "<leader>ml",
    list_all = "<leader>mg",
    remove = "<leader>md",
    next = "<leader>mn",
    previous = "<leader>mp",
  },

  ui = {
    float_border = "rounded",
  },
}

M.options = {}

local function deep_merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      deep_merge(dst[k], v)
    else
      dst[k] = v
    end
  end
  return dst
end

function M.setup(opts)
  M.options = deep_merge(vim.deepcopy(M.defaults), opts or {})
  return M.options
end

return M
