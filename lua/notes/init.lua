local M = {}

local defaults = {
  directory = '~/notes',
  daily_dir = nil,
  file_extension = '.md',
  auto_sync = false,
  register_commands = true,
  map_keys = true,
  keymaps = {
    open_today = '<leader>nt',
    open_notes = '<leader>no',
    sync_notes = '<leader>ns',
  },
}

M.opts = vim.deepcopy(defaults)

M.setup = function(opts)
  opts = opts or {}

  M.opts = vim.tbl_deep_extend('force', {}, defaults, opts)

  if M.opts.auto_sync then
    vim.api.nvim_create_autocmd('BufWritePost', {
      callback = function()
        if M.is_notes_buffer() then
          M.sync_notes()
        end
      end,
      desc = 'Auto-sync notes on save',
    })
  end

  if M.opts.map_keys then
    local keymaps = M.opts.keymaps
    if keymaps.open_today then
      vim.keymap.set('n', keymaps.open_today, M.open_today_note, {
        desc = 'Open or create a note for today',
        noremap = true,
        silent = true,
      })
    end
    if keymaps.open_notes then
      vim.keymap.set('n', keymaps.open_notes, M.open_notes_dir, {
        desc = 'Open the notes directory',
        noremap = true,
        silent = true,
      })
    end
    if keymaps.sync_notes then
      vim.keymap.set('n', keymaps.sync_notes, M.sync_notes, {
        desc = 'Sync notes with git',
        noremap = true,
        silent = true,
      })
    end
  end

  if M.opts.register_commands then
    vim.api.nvim_create_user_command('NotesToday', function(args)
      local arg = args.args
      M.open_today_note(arg)
    end, {
      desc = 'Open or create a note for today',
      nargs = '?',
    })

    vim.api.nvim_create_user_command('Notes', M.open_notes_dir, {
      desc = 'Open the notes directory',
    })

    vim.api.nvim_create_user_command('NotesSync', M.sync_notes, {
      desc = 'Sync notes with git',
    })
  end
end

--- Return normalized notes path, creating the directory if it doesn't exist.
--- @return string|nil
function M.getdir()
  local notesdir = vim.fs.normalize(vim.fn.expand(M.opts.directory))

  if vim.fn.isdirectory(notesdir) == 0 then
    if vim.fn.mkdir(notesdir, 'p') == 0 then
      vim.notify('Failed to create notes directory: ' .. notesdir, vim.log.levels.ERROR)
      return nil
    end
  end

  return notesdir
end

--- Check if the current buffer is a note (i.e., is in the notes directory).
--- @return boolean
function M.is_notes_buffer()
  local notesdir = M.getdir()
  if not notesdir then
    return false
  end
  local bufname = vim.api.nvim_buf_get_name(0)
  return bufname:find(notesdir) == 1
end

--- Create a note with the given name.
--- @param name string
--- @return string|nil
function M.create_note(name)
  local notesdir = M.getdir()
  if not notesdir then
    return nil
  end

  local filepath = vim.fs.joinpath(notesdir, name .. M.opts.file_extension)

  local parent = vim.fs.dirname(filepath)
  if vim.fn.isdirectory(parent) == 0 then
    if vim.fn.mkdir(parent, 'p') == 0 then
      vim.notify('Failed to create parent directory: ' .. parent, vim.log.levels.ERROR)
      return nil
    end
  end

  if vim.fn.filereadable(filepath) == 1 then
    return filepath
  end

  local ok = vim.fn.writefile({ '# ' .. vim.fs.basename(name), '' }, filepath) == 0
  if ok then
    vim.notify('Note created: ' .. filepath, vim.log.levels.INFO)
    return filepath
  else
    vim.notify('Failed to create note: ' .. filepath, vim.log.levels.ERROR)
    return nil
  end
end

--- Open the note for today, creating it if it doesn't exist.
function M.open_today_note(subdir)
  subdir = subdir or M.opts.daily_dir or ''
  local name = vim.fs.joinpath(subdir, vim.fn.strftime '%Y-%m-%d')
  local path = M.create_note(name)
  if not path then
    return
  end
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
end

--- Open the notes directory in a file explorer or telescope. This currently has wacky UX if you
--- have Telescope and the directory is empty.
function M.open_notes_dir()
  local notesdir = M.getdir()
  if not notesdir then
    return
  end

  local ok, telescope = pcall(require, 'telescope.builtin')
  if ok then
    telescope.find_files {
      prompt_title = 'Notes',
      cwd = notesdir,
    }
    return
  end

  vim.cmd('edit ' .. vim.fn.fnameescape(notesdir))
end

--- Sync notes with git, committing and pushing if there are changes.
function M.sync_notes()
  local notesdir = M.getdir()
  if not notesdir then
    return
  end

  local msg = 'notes autocommit: ' .. os.date '%Y-%m-%d %H:%M:%S'

  local function notify(level, text)
    vim.schedule(function()
      vim.notify(text, level)
    end)
  end

  local function fail(cmd, res, extra)
    local detail = (res and res.stderr and res.stderr ~= '' and res.stderr) or (res and res.stdout) or ''
    if extra and extra ~= '' then
      detail = extra .. (detail ~= '' and ('\n' .. detail) or '')
    end

    notify(vim.log.levels.ERROR, ('Git failed (%s): %s'):format(table.concat(cmd, ' '), detail))
  end

  local function run(cmd, on_ok)
    vim.system(cmd, { cwd = notesdir }, function(res)
      if res.code ~= 0 then
        fail(cmd, res)
        return
      end
      if on_ok then
        on_ok(res)
      end
    end)
  end

  run({ 'git', 'rev-parse', '--is-inside-work-tree' }, function(res)
    if not res.stdout:match 'true' then
      fail({ 'git', 'rev-parse', '--is-inside-work-tree' }, res, 'Not a git repository in ' .. notesdir)
      return
    end

    run({ 'git', 'pull', '--rebase', '--autostash' }, function()
      run({ 'git', 'status', '--porcelain' }, function(st)
        local dirty = st.stdout ~= ''

        local function push()
          run({ 'git', 'push' }, function()
            notify(vim.log.levels.INFO, 'Notes: synced' .. (dirty and ' (pull, commit, push)' or ' (no local changes)'))
          end)
        end

        if not dirty then
          -- still push after rebase — there might be new local commits
          push()
          return
        end

        run({ 'git', 'add', '-A' }, function()
          run({ 'git', 'commit', '-m', msg }, function()
            push()
          end)
        end)
      end)
    end)
  end)
end

return M
