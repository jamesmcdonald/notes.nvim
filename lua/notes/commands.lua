local M = {}

function M.register()
  local cfg = require('notes.config').get()
  if not cfg.register_commands then
    return
  end

  vim.api.nvim_create_user_command('NotesToday', function(args)
    require('notes.note').daily_open_today(args.args)
  end, {
    desc = 'Open or create a note for today',
    nargs = '?',
  })

  vim.api.nvim_create_user_command('NotesDate', function(args)
    require('notes.note').open_date(args.args)
  end, {
    desc = 'Open or create a note for a specific date (YYYY-MM-DD)',
    nargs = 1,
  })

  vim.api.nvim_create_user_command('NotesCapture', function(args)
    local note = require('notes.note')
    if args.range > 0 then
      local lines = vim.api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false)
      note.capture(table.concat(lines, '\n'))
    elseif args.args ~= '' then
      note.capture(args.args)
    else
      vim.ui.input({ prompt = 'Capture: ' }, function(input)
        if input and input ~= '' then
          note.capture(input)
        end
      end)
    end
  end, {
    desc = "Capture text to today's note without opening it",
    nargs = '*',
    range = true,
  })

  vim.api.nvim_create_user_command('Notes', require('notes.note').open_notes_dir, {
    desc = 'Open the notes directory',
  })

  vim.api.nvim_create_user_command('NotesSync', require('notes.git').sync_notes, {
    desc = 'Sync notes with git',
  })
end

return M
