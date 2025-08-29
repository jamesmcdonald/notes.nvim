local M = {}

function M.setup(opts)
  require('notes.paths')._resolve_dir()
  require('notes.config').set(opts)
  require('notes.autocmds').apply()
  require('notes.commands').register()
  require('notes.keymaps').apply()
end

M.open_today_note = require('notes.note').daily_open_today
M.open_notes_dir = require('notes.note').open_notes_dir
M.create_note = require('notes.note').open
M.sync_notes = require('notes.git').sync_notes
M.getdir = require('notes.paths').getdir
M.is_notes_buffer = require('notes.paths').is_notes_buffer

return M
