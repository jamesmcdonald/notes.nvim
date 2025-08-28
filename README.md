# notes.nvim

Personal notes for Neovim: daily notes, a simple “open notes” picker, and a tiny
but fairly robust Git sync engine (pull → optional commit → conditional push).

- **Daily notes**: `:NotesToday` creates/opens `YYYY-MM-DD.md` (optionally inside a subdir).
- **Browse notes**: `:Notes` opens your notes directory (uses Telescope if present).
- **Git sync**: `:NotesSync` runs `git pull --rebase --autostash`, then commits/pushes if needed.
- **Background pull**: when you open a note (and when focus returns), a debounced background
  `git pull` runs and the buffer is auto-reloaded if files changed.
- **Quit guard**: on quit, Neovim waits briefly for any in‑flight notes Git job to finish;
  if a sync was queued during a pull, it is kicked off before exit.

> Requires **Neovim 0.10+** (uses `vim.system` and `vim.fs`).

---

## Install

Using **lazy.nvim** (recommended):

```lua
{
  "jamesmcdonald/notes.nvim",
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
  daily_dir = nil,         -- optional subdir for today's notes (e.g. "journal"); nil/"" for none
  file_extension = ".md",  -- extension for notes
  auto_sync = false,       -- run :NotesSync automatically on save for notes buffers
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

**Daily notes inside a subfolder + enable autosync**
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
  - Without an argument, uses `daily_dir` (or none if it’s `nil`/`""`).

- `:Notes`  
  Open the notes directory. If **telescope.nvim** is installed, uses
  `telescope.builtin.find_files{ cwd = notesdir }`. Otherwise `:edit` the dir.

- `:NotesSync`  
  Git sync for the notes repo (non-blocking):
  1. `git rev-parse --is-inside-work-tree` (sanity check)  
  2. `git pull --rebase --autostash`  
  3. `git status --porcelain` → if dirty: `git add -A && git commit -m "notes autocommit: <timestamp>"`  

All Git steps run asynchronously via `vim.system` in **non-interactive** mode
(`GIT_TERMINAL_PROMPT=0`, `GIT_SSH_COMMAND="ssh -o BatchMode=yes"`). Errors surface via `vim.notify`.

---

## Background pull (debounced) & reload

To keep your notes fresh without blocking file open:

- On **BufEnter** for files under your notes directory (and on **FocusGained**), the plugin
  starts a background `git pull --rebase --autostash --quiet`.
- A small **debounce window** (≈10s) prevents redundant network calls while navigating.
- After a successful pull, the plugin runs `:checktime` so any open note buffers reload if changed.

This is automatic; no extra setup needed.

---

## Quit guard

If you quit Neovim while a notes Git job is running, the plugin:

1. waits briefly (≈8–10s) for the in‑flight job to finish, and
2. if a **sync** was queued during a pull, starts that sync before exiting, then waits again.

Notifications during exit may not render depending on your terminal; the wait still applies.
If the timeout is reached, Neovim quits as normal.

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
  - New notes start with:
    ```
    # <basename>
    ```
    (e.g. `# 2025-08-24`).

- **Daily notes**  
  - `open_today_note(subdir?)` builds `subdir/YYYY-MM-DD` and appends `file_extension`.  
  - The `:NotesToday` command passes its optional argument to `open_today_note()`.

- **Sync engine**  
  - Serialized: only one Git job runs at a time; a `:NotesSync` requested
    during a pull is **queued** and runs afterward.  
  - Runs in non-interactive mode to avoid credential or pinentry prompts.

- **Autosync on save**  
  - If `auto_sync = true`, a `BufWritePost` autocommand triggers `:NotesSync` **only for buffers**
    whose path starts with `directory`.

- **Telescope (optional)**  
  - If available, `:Notes` uses `telescope.builtin.find_files` scoped to your notes dir.
    If the directory is empty, Telescope UX can be a little odd; the plugin falls back
    to `:edit` when Telescope isn’t present.

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
notes.sync_notes()                   -- async git sync (pull/commit/conditional push)
```

---

## Roadmap / Nice-to-haves

- File/subdir completion for `:NotesToday` arguments
- “Open by name” prompt (`vim.ui.input`), with subfolder support
- Optional templates/frontmatter
- Configurable debounce/quit time windows

---

## Requirements

- Neovim **0.10+** (`vim.system`, `vim.fs`)
- Git available in `$PATH`
- *(Optional)* [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

---

## License

MIT
