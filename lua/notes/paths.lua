local state = { dir = nil }

local M = {}

--- Resolve and create (if necessary) the notes directory from config.
--- Sets `state.dir` to the normalized path or nil on failure.
--- Called by setup.
function M._resolve_dir()
  local dir = vim.fs.normalize(vim.fn.expand(require('notes.config').get().directory))
  if vim.fn.isdirectory(dir) == 0 then
    if vim.fn.mkdir(dir, 'p') == 0 then
      vim.notify('Failed to create notes directory: ' .. dir, vim.log.levels.ERROR)
      return nil
    end
  end
  state.dir = dir
end

--- Return notes path, or nil if it hasn't been set.
--- @return string|nil
function M.getdir()
  return state.dir
end

--- Check if the current buffer is a note (i.e., is in the notes directory).
--- @return boolean
function M.is_notes_buffer(buf)
  buf = buf or 0
  local bufname = vim.api.nvim_buf_get_name(0)
  local dir = state.dir
  if not dir then
    return false
  end
  return bufname:sub(1, #dir) == dir
end

return M
