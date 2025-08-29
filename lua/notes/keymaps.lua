local M = {}

function M.apply()
  local cfg = require('notes.config').get()
  if not cfg.map_keys then
    return
  end

  local keymaps = cfg.keymaps
  if keymaps.open_today then
    vim.keymap.set('n', keymaps.open_today, require('notes.note').daily_open_today, {
      desc = 'Open or create a note for today',
      noremap = true,
      silent = true,
    })
  end
  if keymaps.open_yesterday then
    vim.keymap.set('n', keymaps.open_yesterday, require('notes.note').daily_open_yesterday, {
      desc = "Open yesterday's note (from a dated file)",
      noremap = true,
      silent = true,
    })
  end
  if keymaps.open_tomorrow then
    vim.keymap.set('n', keymaps.open_tomorrow, require('notes.note').daily_open_tomorrow, {
      desc = "Open tomorrow's note (from a dated file)",
      noremap = true,
      silent = true,
    })
  end
  if keymaps.open_notes then
    vim.keymap.set('n', keymaps.open_notes, require('notes.note').open_notes_dir, {
      desc = 'Open the notes directory',
      noremap = true,
      silent = true,
    })
  end
  if keymaps.grep_notes then
    vim.keymap.set('n', keymaps.grep_notes, require('notes.note').grep_notes, {
      desc = 'Grep notes with Telescope',
      noremap = true,
      silent = true,
    })
  end
  if keymaps.sync_notes then
    vim.keymap.set('n', keymaps.sync_notes, require('notes.git').sync_notes, {
      desc = 'Sync notes with git',
      noremap = true,
      silent = true,
    })
  end
end

return M
