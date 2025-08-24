local Config = require 'notes.config'
local Autocmds = require 'notes.autocmds'
local Commands = require 'notes.commands'
local Keymaps = require 'notes.keymaps'

local M = {}

function M.setup(opts)
  Config.set(opts)
  Autocmds.apply()
  Commands.register()
  Keymaps.apply()
end

M.open_today_note = require('notes.note').open_today_note
M.open_notes_dir = require('notes.note').open_notes_dir
M.create_note = require('notes.note').create_note
M.sync_notes = require('notes.git').sync_notes
M.getdir = require('notes.paths').getdir
M.is_notes_buffer = require('notes.paths').is_notes_buffer

return M
