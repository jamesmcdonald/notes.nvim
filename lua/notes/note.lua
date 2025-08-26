local Config = require 'notes.config'
local Paths = require 'notes.paths'

local M = {}
---
--- Create a note with the given name.
--- @param name string
--- @return string|nil
function M.create_note(name)
  local notesdir = Paths.getdir()
  if not notesdir then
    return nil
  end
  local cfg = Config.get()

  local filepath = vim.fs.joinpath(notesdir, name .. cfg.file_extension)

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

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '# ' .. name, '', '' })
  vim.notify('New note: ' .. filepath, vim.log.levels.INFO)
  return filepath
end

--- Open the note for today, creating it if it doesn't exist.
function M.open_today_note(subdir)
  local cfg = Config.get()
  subdir = subdir or cfg.daily_dir or ''
  local name = vim.fs.joinpath(subdir, vim.fn.strftime '%Y-%m-%d')
  M.create_note(name)
end

--- Open the notes directory in a file explorer or telescope. This currently has wacky UX if you
--- have Telescope and the directory is empty.
function M.open_notes_dir()
  local notesdir = Paths.getdir()
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
  local notesdir = Paths.getdir()
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
