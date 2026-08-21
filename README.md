# mograph.nvim

Connect exact lines of code across multiple files and projects using named
connections — even across separate repos and separate Neovim sessions. Built
for setups like an API server, a mobile app, and an admin dashboard living in
their own repos, where the same logical feature is scattered across files
that don't otherwise reference each other.

```text
create-post-api
├── server/src/routes/posts.ts:42       (repo: server, .git)
├── mobile/src/api/posts.ts:18          (repo: mobile, .git)
└── admin/src/api/posts.ts:24           (repo: admin, .git)
```

## Features

- Line-level connections, not file-level — one line can belong to many
  connections, one connection can span many files.
- **Global by default**: one shared connection graph for your whole system,
  independent of which folder or Neovim session you're in. Open Neovim in
  `~/code/server`, create a connection; open a separate Neovim in
  `~/code/dashboard` later, and add a line there to the same connection —
  no shared parent folder or `.git` required. See
  [Storage modes](#storage-modes) below.
- Visual sign-column markers (`→` single connection, `⇉` multiple) with no
  modification to your source files.
- Locations survive line moves/edits: they're tracked live via extmarks in
  loaded buffers, and relocated on load via stored line/text/symbol context.
- Native floating-window UI — no required dependencies beyond Neovim itself.
- Cross-file `next`/`previous` navigation through every connection, across
  every project.
- JSON persistence, either in one global file or per-project (configurable).

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

## Storage modes

mograph supports two storage modes, set via `storage.mode`:

### `"global"` (default)

One connection graph for your entire system, stored at `storage.global_path`
(defaults to `vim.fn.stdpath("data") .. "/mograph/connections.json"`, e.g.
`~/.local/share/nvim/mograph/connections.json`). Locations are stored as
**absolute file paths**. Because the graph lives at a fixed location instead
of inside any one repo, it doesn't matter which directory you launched
Neovim from, or whether the two files you're connecting belong to the same
repo, different repos, or no repo at all — this is what makes connections
like `server/src/routes/posts.ts` (repo A) ↔ `dashboard/src/api/posts.ts`
(repo B) work out of the box, from two entirely separate Neovim sessions.

```lua
require("mograph").setup({
  storage = {
    mode = "global",
    global_path = vim.fn.stdpath("data") .. "/mograph/connections.json",
  },
})
```

Trade-offs: the file isn't scoped to a repo, so it won't get committed or
shared via git automatically, and if two Neovim instances save at the same
moment it's last-write-wins.

### `"workspace"` (legacy / opt-in)

One connection graph per detected workspace root — the nearest ancestor
directory containing a `.git` or `.mograph` marker (configurable via
`workspace_markers`), searched upward from Neovim's cwd. The graph is stored
at `<root>/<data_dir>/<data_file>` with locations stored **relative to that
root**. Use this if you keep all your related projects as subdirectories of
one parent repo/folder and want the connection graph to travel with it
(e.g. commit `.mograph/connections.json` alongside the code).

```lua
require("mograph").setup({
  storage = { mode = "workspace" },
  data_dir = ".mograph",
  data_file = "connections.json",
  workspace_markers = { ".mograph", ".git" },
})
```

Note: in workspace mode, two files can only be connected if Neovim resolves
them to the *same* workspace root — so this mode still won't bridge two
independently-`.git`-tracked repos unless you point `workspace_markers` at a
shared parent marker (e.g. a `.mograph` file placed at the top of a
monorepo-style folder that contains both repos as subdirectories) or set
`workspace_markers` to something Neovim will only find at that shared
parent.

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
  storage = {
    mode = "global", -- "global" (default) or "workspace" — see Storage modes above
    global_path = vim.fn.stdpath("data") .. "/mograph/connections.json",
  },

  -- Only used when storage.mode == "workspace":
  data_dir = ".mograph",
  data_file = "connections.json",
  workspace_markers = { ".mograph", ".git" },

  signs = {
    enabled = true,
    single = "→",
    multiple = "⇉",
    unresolved = "⨯",
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
`⨯` and "location not found") rather than silently dropped — you can still
see it in `:MoGraph`/`<leader>ml` and remove it manually if it's stale.

## Data format

`~/.local/share/nvim/mograph/connections.json` (global mode, default):

```json
{
  "version": 1,
  "connections": {
    "create-post-api": {
      "locations": [
        {
          "id": "...",
          "file": "/home/you/code/server/src/routes/posts.ts",
          "line": 42,
          "text": "router.post('/posts', createPost)",
          "symbol": "createPost"
        },
        {
          "id": "...",
          "file": "/home/you/code/dashboard/src/api/posts.ts",
          "line": 24,
          "text": "export const createPost = ...",
          "symbol": "createPost"
        }
      ]
    }
  }
}
```

In global mode, `file` is an absolute path, so locations from any project
anywhere on disk can share a connection. In workspace mode, `file` is stored
relative to the detected workspace root instead (see
[Storage modes](#storage-modes)).

## Non-goals (for now)

This first version is deliberately manual and line-level only. Automatic
AST/LSP-based relationship detection, Git integration, connection
tags/descriptions, Telescope/Trouble integration, and dependency-graph
visualization are intentionally left out of scope, but the modular
`connection/` + `ui/` split is meant to make adding them later
straightforward.

## License

MIT
