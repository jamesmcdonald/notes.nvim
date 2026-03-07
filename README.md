# notes.nvim

Personal notes for Neovim: daily notes, a simple “open notes” picker, and a tiny
but fairly robust Git sync engine (pull → optional commit → conditional push).

- **Daily notes**: `:NotesToday` creates/opens `YYYY-MM-DD.md` in the active notes path.
- **Multi-path**: configure multiple note contexts (work, personal, etc.) via `paths`; the active
  path follows your current buffer.
- **Capture**: `:NotesCapture` appends a timestamped entry to today's note without opening it.
- **Browse notes**: `:Notes` opens your active notes path (uses Telescope if present).
- **Grep notes**: `<leader>ng` searches notes with Telescope `live_grep`.
- **Templates**: place `_template.md` in a notes subdir; new notes in that dir use it (supports
  `{{date}}`, `{{time}}`, `{{name}}`).
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
  directory = "~/notes",   -- where notes live (git repo root; created if missing)
  paths = {},              -- subdirs to manage as note contexts (e.g. {"journal", "work"})
  -- daily_dir = nil,      -- deprecated: use paths = {"subdir"} instead
  file_extension = ".md",  -- extension for notes
  auto_sync = false,       -- run :NotesSync automatically on save for notes buffers
  register_commands = true,
  map_keys = true,
  keymaps = {
    open_today     = "<leader>nt",
    open_yesterday = "<leader>np",
    open_tomorrow  = "<leader>nn",
    open_notes     = "<leader>no",
    grep_notes     = "<leader>ng",
    sync_notes     = "<leader>ns",
    capture        = "<leader>nc",
  },
  quit_delay_seconds = 10,
}
```

### Examples

**Basic**
```lua
require(“notes”).setup()
```

**Multiple note contexts (work + journal)**
```lua
require(“notes”).setup({
  paths = { “journal”, “work” },
  auto_sync = true,
})
```
The active path is determined by your current buffer. When no buffer matches, the first path is used.

**Custom keymaps (or disable entirely)**
```lua
require(“notes”).setup({
  map_keys = true,
  keymaps = {
    open_today = “<leader>jd”, -- “journal: today”
    open_notes = “<leader>jo”,
    sync_notes = “<leader>js”,
    capture    = “<leader>jc”,
  },
})
```

---

## Commands

- `:NotesToday [subdir]`
  Create/open today’s note `YYYY-MM-DD.md` in the active path.
  - With an argument, uses that **subdir override**: `:NotesToday work` → `work/YYYY-MM-DD.md`.
  - Without an argument, uses the active path (see [Multi-path](#multi-path)).

- `:NotesDate YYYY-MM-DD`
  Create/open a note for a specific date in the active path.

- `:NotesCapture [text]`
  Append a timestamped bullet to today’s note **without opening it**.
  - With text: `:NotesCapture buy milk` → appends `- HH:MM buy milk`.
  - Without text: opens `vim.ui.input` prompt.
  - In visual mode: captures the selected lines.

- `:Notes`
  Open the active notes path. If **telescope.nvim** is installed, uses
  `telescope.builtin.find_files`. Otherwise `:edit` the dir.

- `:NotesSync`
  Git sync for the notes repo (non-blocking):
  1. `git rev-parse --is-inside-work-tree` (sanity check)
  2. `git pull --rebase --autostash`
  3. `git status --porcelain` → if dirty: `git add -A && git commit -m "notes autocommit: <timestamp>"`

All Git steps run asynchronously via `vim.system` in **non-interactive** mode
(`GIT_TERMINAL_PROMPT=0`, `GIT_SSH_COMMAND="ssh -o BatchMode=yes"`). Errors surface via `vim.notify`.

---

## Multi-path

The `paths` option lets you manage multiple note contexts (e.g. a personal journal and work notes)
inside the same `directory` (git repo):

```lua
require("notes").setup({
  directory = "~/notes",
  paths = { "journal", "work" },
})
```

- Each entry is a subdirectory of `directory`; it is created on startup if missing.
- The **active path** is the configured path that contains the current buffer. If no buffer
  matches, the first path is used.
- Commands like `:NotesToday`, `:Notes`, and `:NotesCapture` all operate on the active path.
- `daily_dir` still works for single-subdir setups but is deprecated; prefer `paths = {"subdir"}`.

---

## Capture

`:NotesCapture` appends a timestamped entry to today's note in the active path **without opening**
the file. Useful for quick thoughts while working in another buffer.

```
:NotesCapture buy oat milk
```

Appends `- 14:32 buy oat milk` to `YYYY-MM-DD.md`. Multi-line input (via `vim.ui.input` or visual
selection) is indented under the timestamp bullet.

If the file doesn't exist yet, a header (`# YYYY-MM-DD`) is written first. If the file is already
open in a buffer, it is reloaded automatically.

---

## Templates

Place a `_template.md` file inside any notes subdirectory. New notes created in that directory will
use it as their initial content instead of the default `# <name>` heading.

Supported placeholders:

| Placeholder  | Replaced with            |
|--------------|--------------------------|
| `{{date}}`   | Current date `YYYY-MM-DD` |
| `{{time}}`   | Current time `HH:MM`     |
| `{{name}}`   | Note filename (no extension) |

Example `_template.md`:

```markdown
# {{name}}

Date: {{date}}
Time: {{time}}

---

```

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

| Key            | Action                                        |
|----------------|-----------------------------------------------|
| `<leader>nt`   | Open/create today’s note (`:NotesToday`)      |
| `<leader>np`   | Open yesterday’s note (from a dated file)     |
| `<leader>nn`   | Open tomorrow’s note (from a dated file)      |
| `<leader>no`   | Open notes directory (`:Notes`)               |
| `<leader>ng`   | Grep notes with Telescope                     |
| `<leader>ns`   | Sync notes (`:NotesSync`)                     |
| `<leader>nc`   | Capture to today’s note (normal + visual)     |

You can disable mappings with `map_keys = false` and add your own:

```lua
vim.keymap.set("n", "<leader>tw", function()
  require("notes.note").daily_open_today("work")  -- subdir override
end, { desc = "Today note (work)" })
```

---

## Behavior & Details

- **Directories**  
  - `directory` is expanded/normalized on use. If missing, it’s created.  
  - When creating a note, parent directories are created as needed (allows subfolders).

- **File format**
  - New notes start with `# <basename>` (e.g. `# 2025-08-24`), unless a `_template.md` exists in
    the same directory (see [Templates](#templates)).

- **Daily notes**
  - `daily_open_today(subdir?)` builds `subdir/YYYY-MM-DD` and appends `file_extension`.
  - The `:NotesToday` command passes its optional argument to `daily_open_today()`.
  - Yesterday/tomorrow navigation (`<leader>np`/`<leader>nn`) works on any file whose name
    contains a `YYYY-MM-DD` date component — not just plain date files.

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
local paths = require("notes.paths")
local note  = require("notes.note")
local git   = require("notes.git")

paths.getdir()             -- -> absolute notes root dir
paths.get_active_path()    -- -> active notes path (context-aware; falls back to first path)
paths.is_notes_buffer()    -- -> true/false (is current buffer inside notes root)

note.open("project/idea-1")          -- open note relative to notes root
note.daily_open_today("work")        -- open today’s note (optional subdir override)
note.daily_open_yesterday()          -- open yesterday’s note (from current dated buffer)
note.daily_open_tomorrow()           -- open tomorrow’s note (from current dated buffer)
note.open_date("2025-08-24")         -- open note for a specific date in active path
note.capture("text")                 -- append timestamped entry to today’s note
note.open_notes_dir()                -- browse active path (Telescope if available)
note.grep_notes()                    -- grep active path with Telescope live_grep

git.sync_notes()                     -- async git sync (pull/commit/conditional push)
```

---

## Roadmap / Nice-to-haves

- File/subdir completion for `:NotesToday` arguments
- “Open by name” prompt (`vim.ui.input`), with subfolder support
- Configurable debounce time window

---

## Requirements

- Neovim **0.10+** (`vim.system`, `vim.fs`)
- Git available in `$PATH`
- *(Optional)* [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

---

## License

MIT
