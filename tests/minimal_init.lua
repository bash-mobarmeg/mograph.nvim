-- Minimal init for running the test suite headlessly with plenary.nvim:
--
--   nvim --headless -u tests/minimal_init.lua \
--     -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
--
-- Assumes plenary.nvim is available on the runtimepath (e.g. installed
-- alongside this plugin in ~/.local/share/nvim/site/pack/*/start/).

local plenary_dir = os.getenv("PLENARY_DIR") or "~/.local/share/nvim/site/pack/vendor/start/plenary.nvim"
vim.opt.rtp:append(".")
vim.opt.rtp:append(plenary_dir)

vim.cmd("runtime plugin/plenary.vim")
