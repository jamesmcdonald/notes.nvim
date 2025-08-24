local config = require 'notes.config'

local M = {}

--- Return normalized notes path, creating the directory if it doesn't exist.
--- @return string|nil
function M.getdir()
  local notesdir = vim.fs.normalize(vim.fn.expand(config.get().directory))

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

return M
