local M = {}

--- Open a note with the given name (relative to the notes root).
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

  local template_path = vim.fs.joinpath(parent, '_template.md')
  local lines
  if vim.fn.filereadable(template_path) == 1 then
    local date = name:match '%d%d%d%d%-%d%d%-%d%d' or vim.fn.strftime '%Y-%m-%d'
    local time = vim.fn.strftime '%H:%M'
    lines = vim.tbl_map(function(line)
      return (line:gsub('{{date}}', date):gsub('{{time}}', time):gsub('{{name}}', name))
    end, vim.fn.readfile(template_path))
  else
    lines = { '# ' .. name, '' }
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modified', false, { buf = bufnr })
  vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(bufnr), 0 })
  vim.notify('New note: ' .. filepath, vim.log.levels.INFO)
  return filepath
end

--- Open the note for today in the active notes path.
--- @param subdir? string override subdir (relative to root, for backward compat)
function M.daily_open_today(subdir)
  local cfg = require('notes.config').get()
  local date = vim.fn.strftime '%Y-%m-%d'
  local basedir
  if subdir and subdir ~= '' then
    basedir = vim.fs.joinpath(require('notes.paths').getdir(), subdir)
  else
    basedir = require('notes.paths').get_active_path()
  end
  M.open_absolute(vim.fs.joinpath(basedir, date .. cfg.file_extension))
end

function M.daily_open_adjacent(forward)
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local dirname = vim.fs.dirname(bufname)
  local basename = vim.fs.basename(bufname)
  local _, _, prefix, datebit, suffix = string.find(basename, '^(.*)(%d%d%d%d%-%d%d%-%d%d)(.*)$')
  local date = vim.fn.strptime('%Y-%m-%d', datebit)
  if date == 0 then
    vim.notify('Current buffer is not a date-named note', vim.log.levels.ERROR)
    return
  end
  if forward then
    date = date + 24 * 60 * 60
  else
    date = date - 24 * 60 * 60
  end
  local name = vim.fs.joinpath(dirname, prefix .. vim.fn.strftime('%Y-%m-%d', date)) .. suffix
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

--- Open the note for a specific date in the active notes path.
--- @param date_str string date in YYYY-MM-DD format
function M.open_date(date_str)
  if not date_str or date_str == '' then
    vim.notify('NotesDate requires a date (YYYY-MM-DD)', vim.log.levels.ERROR)
    return
  end
  if not date_str:match '^%d%d%d%d%-%d%d%-%d%d$' then
    vim.notify('Invalid date format, expected YYYY-MM-DD: ' .. date_str, vim.log.levels.ERROR)
    return
  end
  local cfg = require('notes.config').get()
  local active = require('notes.paths').get_active_path()
  M.open_absolute(vim.fs.joinpath(active, date_str .. cfg.file_extension))
end

--- Append a captured note to today's file in the active notes path, without opening it.
--- @param text string
function M.capture(text)
  local cfg = require('notes.config').get()
  local active = require('notes.paths').get_active_path()
  local date = vim.fn.strftime '%Y-%m-%d'
  local time = vim.fn.strftime '%H:%M'
  local filepath = vim.fs.joinpath(active, date .. cfg.file_extension)

  local parent = vim.fs.dirname(filepath)
  if vim.fn.isdirectory(parent) == 0 then
    vim.fn.mkdir(parent, 'p')
  end

  local is_new = vim.fn.filereadable(filepath) == 0
  local lines = vim.split(text, '\n', { plain = true })
  local entry
  if #lines <= 1 then
    entry = '- ' .. time .. ' ' .. text
  else
    local indented = vim.tbl_map(function(l)
      return '  ' .. l
    end, lines)
    entry = '- ' .. time .. '\n' .. table.concat(indented, '\n')
  end

  local file = io.open(filepath, 'a')
  if not file then
    vim.notify('Failed to open ' .. filepath, vim.log.levels.ERROR)
    return
  end
  if is_new then
    file:write('# ' .. date .. '\n\n' .. entry .. '\n')
  else
    file:write('\n' .. entry .. '\n')
  end
  file:close()

  -- Reload buffer if the file is already open
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf) == filepath then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd 'checktime'
      end)
      break
    end
  end

  vim.notify('Captured to ' .. vim.fs.basename(filepath), vim.log.levels.INFO)

  if cfg.auto_sync then
    require('notes.git').sync_notes()
  end
end

--- Open the notes directory in a file explorer or telescope.
function M.open_notes_dir()
  local notesdir = require('notes.paths').get_active_path()
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
  local notesdir = require('notes.paths').get_active_path()
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
