local state = { dir = nil, paths = {} }

local M = {}

local function normalize_bufname(bufname)
  return (bufname:gsub('^oil://', ''):gsub('/$', ''))
end

local function resolve_and_mkdir(path)
  local p = vim.fs.normalize(vim.fn.expand(path))
  if vim.fn.isdirectory(p) == 0 then
    if vim.fn.mkdir(p, 'p') == 0 then
      vim.notify('Failed to create notes directory: ' .. p, vim.log.levels.ERROR)
      return nil
    end
  end
  return p
end

--- Resolve and create (if necessary) the notes directory and configured paths from config.
--- Called by setup.
function M._resolve_paths()
  local cfg = require('notes.config').get()
  local dir = resolve_and_mkdir(cfg.directory)
  if not dir then
    return
  end
  state.dir = dir

  state.paths = {}
  if cfg.paths and #cfg.paths > 0 then
    for _, subpath in ipairs(cfg.paths) do
      local fullpath = resolve_and_mkdir(vim.fs.joinpath(dir, subpath))
      if fullpath then
        table.insert(state.paths, fullpath)
      end
    end
  else
    -- Backward compat: promote daily_dir to a single path entry
    local daily = cfg.daily_dir or ''
    if daily ~= '' then
      local fullpath = resolve_and_mkdir(vim.fs.joinpath(dir, daily))
      if fullpath then
        table.insert(state.paths, fullpath)
      end
    else
      table.insert(state.paths, dir)
    end
  end
end

M._resolve_dir = M._resolve_paths

--- Return the notes root path (git repo root), or nil if not set.
--- @return string|nil
function M.getdir()
  return state.dir
end

--- Return the active notes path for the given buffer.
--- Uses the configured path that contains the buffer, falling back to the first path.
--- @param buf? number
--- @return string|nil
function M.get_active_path(buf)
  buf = buf or 0
  local bufname = normalize_bufname(vim.api.nvim_buf_get_name(buf))
  for _, path in ipairs(state.paths) do
    if bufname == path or bufname:sub(1, #path + 1) == path .. '/' then
      return path
    end
  end
  return state.paths[1] or state.dir
end

--- Check if a buffer is a notes buffer (anywhere under the notes root).
--- @param buf? number
--- @return boolean
function M.is_notes_buffer(buf)
  buf = buf or 0
  local bufname = normalize_bufname(vim.api.nvim_buf_get_name(buf))
  local dir = state.dir
  if not dir then
    return false
  end
  return bufname == dir or bufname:sub(1, #dir + 1) == dir .. '/'
end

return M
