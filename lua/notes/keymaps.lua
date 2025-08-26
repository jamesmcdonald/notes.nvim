local Config = require 'notes.config'
local Note = require 'notes.note'
local Git = require 'notes.git'

local M = {}

function M.apply()
  local cfg = Config.get()
  if not cfg.map_keys then
    return
  end

  local keymaps = cfg.keymaps
  if keymaps.open_today then
    vim.keymap.set('n', keymaps.open_today, Note.daily_open_today, {
      desc = 'Open or create a note for today',
      noremap = true,
      silent = true,
    })
  end
  if keymaps.open_yesterday then
    vim.keymap.set('n', keymaps.open_yesterday, Note.daily_open_yesterday, {
      desc = "Open yesterday's note (from a dated file)",
      noremap = true,
      silent = true,
    })
  end
  if keymaps.open_tomorrow then
    vim.keymap.set('n', keymaps.open_tomorrow, Note.daily_open_tomorrow, {
      desc = "Open tomorrow's note (from a dated file)",
      noremap = true,
      silent = true,
    })
  end
  if keymaps.open_notes then
    vim.keymap.set('n', keymaps.open_notes, Note.open_notes_dir, {
      desc = 'Open the notes directory',
      noremap = true,
      silent = true,
    })
  end
  if keymaps.grep_notes then
    vim.keymap.set('n', keymaps.grep_notes, Note.grep_notes, {
      desc = 'Grep notes with Telescope',
      noremap = true,
      silent = true,
    })
  end
  if keymaps.sync_notes then
    vim.keymap.set('n', keymaps.sync_notes, Git.sync_notes, {
      desc = 'Sync notes with git',
      noremap = true,
      silent = true,
    })
  end
end

return M
