if vim.g.loaded_mograph then
  return
end
vim.g.loaded_mograph = true

-- mograph.nvim does not auto-configure itself. Call
-- require("mograph").setup({...}) from your Neovim config to enable
-- commands, keymaps, and autocmds. See README.md for available options.
