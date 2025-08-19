local M = {}

local defaults = {
  notes_dir = '~/notes',
  file_extension = '.md',
}

M.opts = vim.deepcopy(defaults)

M.setup = function(opts)
  opts = opts or {}

  M.opts = vim.tbl_deep_extend('force', {}, defaults, opts)
end

--- Return normalized notes path, creating the directory if it doesn't exist.
--- @return string|nil
function M.get_notes_dir()
  local notesdir = vim.fs.normalize(vim.fn.expand(M.opts.notes_dir))

  if vim.fn.isdirectory(notesdir) == 0 then
    if vim.fn.mkdir(notesdir, 'p') == 0 then
      vim.notify('Failed to create notes directory: ' .. notesdir, vim.log.levels.ERROR)
      return nil
    end
  end

  return notesdir
end

--- Create a note with the given name.
--- @param name string
--- @return string|nil
function M.create_note(name)
  local notesdir = M.get_notes_dir()
  if not notesdir then
    return nil
  end

  local filepath = vim.fs.joinpath(notesdir, name .. M.opts.file_extension)

  if vim.fn.filereadable(filepath) == 1 then
    return filepath
  end

  local ok = vim.fn.writefile({ '# ' .. name, '' }, filepath) == 0
  if ok then
    vim.notify('Note created: ' .. filepath, vim.log.levels.INFO)
    return filepath
  else
    vim.notify('Failed to create note: ' .. filepath, vim.log.levels.ERROR)
    return nil
  end
end

--- Open the note for today, creating it if it doesn't exist.
function M.open_today_note()
  local name = vim.fn.strftime '%Y-%m-%d'
  local path = M.create_note(name)
  if not path then
    return
  end
  vim.cmd('edit ' .. vim.fn.fnameescape(path))
end

--- Open the notes directory in a file explorer or telescope. This currently has wacky UX if you
--- have Telescope and the directory is empty.
function M.open_notes_dir()
  local notesdir = M.get_notes_dir()
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

-- Git stuff

--- Do we have fugitive?
--- @return boolean
local function has_fugitive()
  return vim.fn.exists ':Git' == 2
end

--- Check if the current git repository is dirty (has uncommitted changes).
--- @param cwd string The directory to check. Defaults to the current working directory.
--- @return boolean True if the repository is dirty, false otherwise.
local function repo_dirty(cwd)
  local r = vim.system({ 'git', 'status', '--porcelain' }, { cwd = cwd, text = true }):wait()
  return r.code == 0 and r.stdout ~= ''
end

--- Sync notes with git, committing and pushing if there are changes. This is
--- super simple and will break if you don't have a git repo or you don't have
--- all the necessary settings or you don't have a remote.
function M.sync_notes()
  local notesdir = M.get_notes_dir()
  if not notesdir then
    return
  end
  local msg = 'notes autocommit: ' .. os.date '%Y-%m-%d %H:%M:%S'

  if not repo_dirty(notesdir) then
    vim.notify('Notes: nothing to commit', vim.log.levels.INFO)
    return
  end

  if has_fugitive() and vim.fs.dirname(vim.api.nvim_buf_get_name(0)):find(notesdir, 1, true) then
    vim.cmd 'Git add -A'
    vim.cmd('Git commit -m ' .. vim.fn.shellescape(msg))
    vim.cmd 'Git push'
    vim.notify('Notes: committed & pushed via Fugitive', vim.log.levels.INFO)
    return
  end

  local function run(cmd)
    local r = vim.system(cmd, { cwd = notesdir }):wait()
    if r.code ~= 0 then
      vim.notify('Git failed: ' .. table.concat(cmd, ' '), vim.log.levels.ERROR)
      return false
    end
    return true
  end

  if run { 'git', 'add', '-A' } and run { 'git', 'commit', '-m', msg } and run { 'git', 'push' } then
    vim.notify('Notes: committed & pushed', vim.log.levels.INFO)
  end
end

-- Inject commands TODO: investigate if these would be happier behind the setup function

vim.api.nvim_create_user_command('NotesToday', M.open_today_note, {
  desc = 'Open or create a note for today',
})

vim.api.nvim_create_user_command('Notes', M.open_notes_dir, {
  desc = 'Open the notes directory',
})

vim.api.nvim_create_user_command('NotesSync', M.sync_notes, {
  desc = 'Sync notes with git',
})

return M
