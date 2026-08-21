local model = require("mograph.connection.model")
local config = require("mograph.config")
local utils = require("mograph.utils")

describe("mograph.config", function()
  it("merges user options over defaults without mutating defaults", function()
    local opts = config.setup({ signs = { single = "X" } })
    assert.equals("X", opts.signs.single)
    assert.equals("⇉", opts.signs.multiple)
    assert.equals("→", config.defaults.signs.single)
  end)

  it("defaults to global storage mode with a stdpath-based path", function()
    local opts = config.setup({})
    assert.equals("global", opts.storage.mode)
    assert.is_not_nil(opts.storage.global_path:find("mograph/connections.json"))
  end)
end)

describe("mograph.utils", function()
  it("converts absolute paths to workspace-relative paths", function()
    local rel = utils.to_relative("/workspace/server/src/routes/posts.ts", "/workspace")
    assert.equals("server/src/routes/posts.ts", rel)
  end)

  it("round-trips relative -> absolute paths", function()
    local abs = utils.to_absolute("server/src/routes/posts.ts", "/workspace")
    assert.equals("/workspace/server/src/routes/posts.ts", abs)
  end)

  it("trims whitespace", function()
    assert.equals("hello", utils.trim("  hello  "))
  end)
end)

describe("mograph.connection.model", function()
  it("builds a location using the given storage-path converter (global mode style)", function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, "/workspace/server/src/routes/posts.ts")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      "import express from 'express'",
      "",
      "function createPost(req, res) {",
      "  router.post('/posts', createPost)",
      "}",
    })

    local win = vim.api.nvim_open_win(bufnr, true, {
      relative = "editor",
      row = 0,
      col = 0,
      width = 40,
      height = 5,
    })
    vim.api.nvim_win_set_cursor(win, { 4, 0 })

    -- "global" mode: locations are stored as absolute paths, unchanged.
    local to_storage_path = function(abs_path)
      return abs_path
    end

    local loc = model.new_location(bufnr, to_storage_path)

    assert.equals("/workspace/server/src/routes/posts.ts", loc.file)
    assert.equals(4, loc.line)
    assert.equals("  router.post('/posts', createPost)", loc.text)
    assert.is_not_nil(loc.id)

    vim.api.nvim_win_close(win, true)
  end)

  it("builds a location using a workspace-relative converter (workspace mode style)", function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, "/workspace/server/src/routes/posts.ts")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "line one" })

    local win = vim.api.nvim_open_win(bufnr, true, {
      relative = "editor",
      row = 0,
      col = 0,
      width = 40,
      height = 5,
    })
    vim.api.nvim_win_set_cursor(win, { 1, 0 })

    local to_storage_path = function(abs_path)
      return utils.to_relative(abs_path, "/workspace")
    end

    local loc = model.new_location(bufnr, to_storage_path)
    assert.equals("server/src/routes/posts.ts", loc.file)

    vim.api.nvim_win_close(win, true)
  end)

  it("detects same_place for matching file+line", function()
    local a = { file = "a.ts", line = 1 }
    local b = { file = "a.ts", line = 1 }
    local c = { file = "a.ts", line = 2 }
    assert.is_true(model.same_place(a, b))
    assert.is_false(model.same_place(a, c))
  end)
end)
