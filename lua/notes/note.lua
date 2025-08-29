local M = {}

--- Open a note with the given name.
--- @param name string
--- @return string|nil
function M.open(name)
  local notesdir = require('notes.paths').getdir()
  if not notesdir then
    return nil
  end
  local cfg = require('notes.config').get()

  local filepath = vim.fs.joinpath(notesdir, name .. cfg.file_extension)
  return M.open_absolute(filepath)
end

function M.open_absolute(filepath)
  local parent = vim.fs.dirname(filepath)
  if vim.fn.isdirectory(parent) == 0 then
    if vim.fn.mkdir(parent, 'p') == 0 then
      vim.notify('Failed to create parent directory: ' .. parent, vim.log.levels.ERROR)
      return nil
    end
  end

  vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
  if vim.fn.filereadable(filepath) == 1 then
    return filepath
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local name = vim.fs.basename(filepath)
  name = name:gsub('%..*$', '')

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '# ' .. name, '', '' })
  vim.api.nvim_set_option_value('modified', false, { buf = bufnr })
  vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(bufnr), 0 })
  vim.notify('New note: ' .. filepath, vim.log.levels.INFO)
  return filepath
end

--- Open the note for today
function M.daily_open_today(subdir)
  local cfg = require('notes.config').get()
  subdir = subdir or cfg.daily_dir or ''
  local name = vim.fs.joinpath(subdir, vim.fn.strftime '%Y-%m-%d')
  M.open(name)
end

function M.daily_open_adjacent(forward)
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local dirname = vim.fs.dirname(bufname)
  local basename = vim.fs.basename(bufname)
  -- Match a date in the basename, and save everything that comes after it
  local _, _, suffix = string.find(basename, '^%d%d%d%d%-%d%d%-%d%d(.*)$')
  local date = vim.fn.strptime('%Y-%m-%d', basename)
  if date == 0 then
    vim.notify('Current buffer is not a date-named note', vim.log.levels.ERROR)
    return
  end
  if forward then
    date = date + 24 * 60 * 60
  else
    date = date - 24 * 60 * 60
  end
  local name = vim.fs.joinpath(dirname, vim.fn.strftime('%Y-%m-%d', date)) .. suffix

  M.open_absolute(name)
end

--- Open yesterday's note from a date-named file in the same directory
function M.daily_open_yesterday()
  M.daily_open_adjacent(false)
end

--- Open tomorrow's note
function M.daily_open_tomorrow()
  M.daily_open_adjacent(true)
end

--- Open the notes directory in a file explorer or telescope. This currently has wacky UX if you
--- have Telescope and the directory is empty.
function M.open_notes_dir()
  local notesdir = require('notes.paths').getdir()
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

function M.grep_notes()
  local notesdir = require('notes.paths').getdir()
  if not notesdir then
    return
  end
  local ok, telescope = pcall(require, 'telescope.builtin')
  if ok then
    telescope.live_grep {
      prompt_title = 'Grep Notes',
      cwd = notesdir,
    }
    return
  end
  vim.notify('Telescope not found', vim.log.levels.ERROR)
end

return M
