local Config = require 'notes.config'
local Autocmds = require 'notes.autocmds'
local Commands = require 'notes.commands'
local Keymaps = require 'notes.keymaps'
local Paths = require 'notes.paths'

local M = {}

function M.setup(opts)
  Paths._resolve_dir()
  Config.set(opts)
  Autocmds.apply()
  Commands.register()
  Keymaps.apply()
end

M.open_today_note = require('notes.note').daily_open_today
M.open_notes_dir = require('notes.note').open_notes_dir
M.create_note = require('notes.note').open
M.sync_notes = require('notes.git').sync_notes
M.getdir = require('notes.paths').getdir
M.is_notes_buffer = require('notes.paths').is_notes_buffer

return M
