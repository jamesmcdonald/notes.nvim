local M = {}

function M.register()
  local cfg = require('notes.config').get()
  if not cfg.register_commands then
    return
  end

  vim.api.nvim_create_user_command('NotesToday', function(args)
    local arg = args.args
    require('notes.note').daily_open_today(arg)
  end, {
    desc = 'Open or create a note for today',
    nargs = '?',
  })

  vim.api.nvim_create_user_command('Notes', require('notes.note').open_notes_dir, {
    desc = 'Open the notes directory',
  })

  vim.api.nvim_create_user_command('NotesSync', require('notes.git').sync_notes, {
    desc = 'Sync notes with git',
  })
end

return M
