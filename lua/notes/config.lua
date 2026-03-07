local M = {}

local defaults = {
  directory = '~/notes',
  daily_dir = nil, -- deprecated: use paths instead
  paths = {}, -- subdirectories of directory to manage as note contexts
  file_extension = '.md',
  auto_sync = false,
  register_commands = true,
  map_keys = true,
  keymaps = {
    open_today = '<leader>nt',
    open_yesterday = '<leader>np',
    open_tomorrow = '<leader>nn',
    open_notes = '<leader>no',
    grep_notes = '<leader>ng',
    sync_notes = '<leader>ns',
    capture = '<leader>nc',
  },
  quit_delay_seconds = 10,
}

M.opts = vim.deepcopy(defaults)

function M.set(user)
  M.opts = vim.tbl_deep_extend('force', {}, defaults, user or {})
  return M.opts
end

function M.get()
  return M.opts
end

return M
