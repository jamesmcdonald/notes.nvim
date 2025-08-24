local Config = require 'notes.config'
local Note = require 'notes.note'
local Git = require 'notes.git'

local M = {}

function M.register()
  local cfg = Config.get()
  if not cfg.register_commands then
    return
  end

  vim.api.nvim_create_user_command('NotesToday', function(args)
    local arg = args.args
    Note.open_today_note(arg)
  end, {
    desc = 'Open or create a note for today',
    nargs = '?',
  })

  vim.api.nvim_create_user_command('Notes', Note.open_notes_dir, {
    desc = 'Open the notes directory',
  })

  vim.api.nvim_create_user_command('NotesSync', Git.sync_notes, {
    desc = 'Sync notes with git',
  })
end

return M
