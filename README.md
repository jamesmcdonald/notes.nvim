# notes.nvim

Lightweight personal notes for Neovim: daily notes, a simple “open notes” picker, and optional Git sync (pull → add/commit → push).

- **Daily notes**: `:NotesToday` creates/opens `YYYY-MM-DD.md` (optionally inside a subdir like `journal/`).
- **Browse notes**: `:Notes` opens your notes directory (uses Telescope if present).
- **Git sync**: `:NotesSync` runs `git pull --rebase --autostash`, then commits/pushes if there are changes.  
  Optionally auto-sync on save for files inside your notes dir.

> Requires **Neovim 0.10+** (uses `vim.system` and `vim.fs`).

---

## Install

Using **lazy.nvim** (recommended):

```lua
{
  -- replace with your repo path
  "yourname/notes.nvim",
  opts = {
    -- overrides here (see “Configuration”)
  },
}
```

Or manually:

```lua
require("notes").setup({
  -- overrides here
})
```

---

## Configuration

These are the defaults as implemented:

```lua
{
  directory = "~/notes",   -- where notes live (created if missing)
  daily_dir = nil,         -- optional subdir for today's notes
  file_extension = ".md",  -- extension for notes
  auto_sync = false,       -- auto run :NotesSync on save for notes buffers
  register_commands = true,
  map_keys = true,
  keymaps = {
    open_today = "<leader>nt",
    open_notes = "<leader>no",
    sync_notes = "<leader>ns",
  },
}
```

### Examples

**Basic**
```lua
require("notes").setup()
```

**No subdir for daily notes + enable autosync**
```lua
require("notes").setup({
  daily_dir = "journal",
  auto_sync = true,
})
```

**Custom keymaps (or disable entirely)**
```lua
require("notes").setup({
  map_keys = true,
  keymaps = {
    open_today = "<leader>jd", -- “journal: today”
    open_notes = "<leader>jo",
    sync_notes = "<leader>js",
  },
})
```

---

## Commands

- `:NotesToday [subdir]`  
  Create/open today’s note `YYYY-MM-DD.md`.  
  - With an argument, uses that **subdir override**: `:NotesToday work` → `work/2025-08-24.md`.  
  - Without an argument, uses `daily_dir` (or none if it’s `""`).

- `:Notes`  
  Open the notes directory. If **telescope.nvim** is installed, uses `telescope.builtin.find_files{ cwd = notesdir }`. Otherwise `:edit` the dir.

- `:NotesSync`  
  Git sync for the notes repo (non-blocking):
  1. `git rev-parse --is-inside-work-tree` (sanity check)  
  2. `git pull --rebase --autostash`  
  3. `git status --porcelain` → if dirty: `git add -A && git commit -m "notes autocommit: <timestamp>"`  
  4. `git push`

> All Git steps run asynchronously via `vim.system`. Errors surface via `vim.notify`.

---

## Keymaps

If `map_keys = true`, the plugin sets:

- **`<leader>nt`** → open/create today’s note (`:NotesToday`)
- **`<leader>no`** → open notes directory (`:Notes`)
- **`<leader>ns`** → sync notes (`:NotesSync`)

You can disable mappings with `map_keys = false` and add your own:

```lua
vim.keymap.set("n", "<leader>tw", function()
  require("notes").open_today_note("work")  -- override subdir
end, { desc = "Today note (work)" })
```

---

## Behavior & Details

- **Directories**  
  - `directory` is expanded/normalized on use. If missing, it’s created.  
  - When creating a note, parent directories are created as needed (allows subfolders).

- **File format**  
  - New notes are created with a simple header:
    ```
    # <basename>
    ```
    (e.g. `# 2025-08-24`)

- **Daily notes**  
  - `open_today_note(subdir?)` builds `subdir/YYYY-MM-DD` and appends `file_extension`.  
  - The `:NotesToday` command passes its optional argument to `open_today_note()`.

- **Git sync**  
  - Runs only if `directory` is a Git repo.  
  - Uses `vim.system` (async), so Neovim stays responsive.  
  - Always attempts a `push` after checking for local changes (useful after a rebase).  
  - You’ll need a configured remote and working auth (e.g. SSH agent/credential helper).

- **Autosync on save**  
  - If `auto_sync = true`, a `BufWritePost` autocommand triggers `sync_notes()` **only for buffers** whose path starts with `directory`.

- **Telescope (optional)**  
  - If available, `:Notes` uses `telescope.builtin.find_files` scoped to your notes dir.  
  - If the directory is empty, Telescope UX can be a little odd; the plugin falls back to `:edit` when Telescope isn’t present.

---

## Public API

You can call these directly:

```lua
local notes = require("notes")

notes.getdir()            -- -> absolute notes dir (ensures it exists)
notes.is_notes_buffer()   -- -> true/false (is current buffer inside notes dir)

notes.create_note("project/idea-1")  -- creates/openable path string or nil
notes.open_today_note("work")        -- open today’s note (override subdir)
notes.open_notes_dir()               -- browse notes (Telescope if available)
notes.sync_notes()                   -- async git sync (pull/commit/push)
```

---

## Requirements

- Neovim **0.10+** (for `vim.system` + modern `vim.fs`)
- Git available in `$PATH`
- *(Optional)* [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

---

## Roadmap / Nice-to-haves (future)

- File/subdir completion for `:NotesToday` arguments
- “Open by name” prompt (`vim.ui.input`), with subfolder support
- Push-only-if-ahead optimization
- Optional templates/frontmatter
- `VimLeavePre` wait if an async git job is running

---

## License

MIT
