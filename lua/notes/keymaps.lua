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
    vim.keymap.set('n', keymaps.open_today, Note.open_today_note, {
      desc = 'Open or create a note for today',
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
  if keymaps.sync_notes then
    vim.keymap.set('n', keymaps.sync_notes, Git.sync_notes, {
      desc = 'Sync notes with git',
      noremap = true,
      silent = true,
    })
  end
end

return M
