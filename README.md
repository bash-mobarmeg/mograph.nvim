# mograph.nvim

Connect exact lines of code across multiple files and projects using named
connections. Built for multi-project workspaces (e.g. an API server, a
mobile app, and an admin dashboard living side by side) where the same
logical feature is scattered across files that don't otherwise reference
each other.

```text
create-post-api
├── server/src/routes/posts.ts:42
├── mobile/src/api/posts.ts:18
└── admin/src/api/posts.ts:24
```

## Features

- Line-level connections, not file-level — one line can belong to many
  connections, one connection can span many files.
- Visual sign-column markers (`●` single connection, `◆` multiple) with no
  modification to your source files.
- Locations survive line moves/edits: they're tracked live via extmarks in
  loaded buffers, and relocated on load via stored line/text/symbol context.
- Native floating-window UI — no required dependencies beyond Neovim itself.
- Cross-file `next`/`previous` navigation through every connection in the
  workspace.
- JSON persistence in `.mograph/connections.json` at the workspace root.

## Installation

**lazy.nvim**

```lua
{
  "yourname/mograph.nvim",
  config = function()
    require("mograph").setup()
  end,
}
```

**packer.nvim**

```lua
use({
  "yourname/mograph.nvim",
  config = function()
    require("mograph").setup()
  end,
})
```

## Usage

1. Put your cursor on a line and press `<leader>mc` (or run
   `:MoGraphCreate`). You'll be prompted for a connection name.
2. Move to another file/line, press `<leader>ma` (`:MoGraphAdd`), and pick
   the connection to add this line to.
3. Press `<leader>ml` (`:MoGraphList`) on any connected line to see every
   connection — and every location within it — that passes through that
   line. Select an entry to jump there.
4. Press `<leader>mg` (`:MoGraph` / `:MoGraphConnections`) to browse every
   connection in the workspace.
5. Press `<leader>mn` / `<leader>mp` (`:MoGraphNext` / `:MoGraphPrevious`)
   to step through every connected location across the whole workspace.
6. Press `<leader>md` (`:MoGraphRemove`) to remove the current line from a
   connection (prompts if the line belongs to more than one), or use
   `:MoGraphDelete` to delete an entire connection.

### Floating window controls

Inside any mograph list/tree window: `<CR>` selects, `q` or `<Esc>` closes.

## Commands

| Command                 | Description                                   |
| ------------------------ | ---------------------------------------------- |
| `:MoGraphCreate`       | Create a connection from the current line     |
| `:MoGraphAdd`          | Add the current line to an existing connection |
| `:MoGraphList`         | Show connections at the current line          |
| `:MoGraph` / `:MoGraphConnections` | List every connection in the workspace |
| `:MoGraphRemove`       | Remove the current line from a connection     |
| `:MoGraphDelete`       | Delete an entire connection                   |
| `:MoGraphNext`         | Jump to the next connected location           |
| `:MoGraphPrevious`     | Jump to the previous connected location       |
| `:MoGraphRefresh`      | Recompute signs for all open buffers          |

## Default keymaps

```lua
{
  create       = "<leader>mc",
  add          = "<leader>ma",
  list_current = "<leader>ml",
  list_all     = "<leader>mg",
  remove       = "<leader>md",
  next         = "<leader>mn",
  previous     = "<leader>mp",
}
```

Set `keymaps.enabled = false` to disable all default keymaps and wire your
own, e.g.:

```lua
vim.keymap.set("n", "<leader>xx", require("mograph").create_connection)
```

## Configuration

```lua
require("mograph").setup({
  data_dir = ".mograph",
  data_file = "connections.json",

  -- Files/directories that mark the workspace root, searched upward from cwd.
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
})
```

## How locations are tracked

Each location stores its file, line, the line's text at capture time, and
(when detectable) an enclosing function/symbol name. When resolving a
location, mograph tries, in order:

1. A live extmark in the loaded buffer (survives edits in the current
   session).
2. The stored line number, verified against stored text.
3. A text search radiating outward from the stored line, then a full-buffer
   scan.
4. A search for the stored symbol name.

If none of these succeed, the location is marked unresolved (shown with
`⚠` and "location not found") rather than silently dropped — you can still
see it in `:MoGraph`/`<leader>ml` and remove it manually if it's stale.

## Data format

`.mograph/connections.json`:

```json
{
  "version": 1,
  "connections": {
    "create-post-api": {
      "locations": [
        {
          "id": "...",
          "file": "server/src/routes/posts.ts",
          "line": 42,
          "text": "router.post('/posts', createPost)",
          "symbol": "createPost"
        }
      ]
    }
  }
}
```

Paths are stored relative to the detected workspace root.

## Non-goals (for now)

This first version is deliberately manual and line-level only. Automatic
AST/LSP-based relationship detection, Git integration, connection
tags/descriptions, Telescope/Trouble integration, and dependency-graph
visualization are intentionally left out of scope, but the modular
`connection/` + `ui/` split is meant to make adding them later
straightforward.

## License

MIT
