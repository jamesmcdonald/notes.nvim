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
    open_yesterday = '<leader>np',
    open_tomorrow = '<leader>nn',
    open_notes = '<leader>no',
    grep_notes = '<leader>ng',
    sync_notes = '<leader>ns',
  },
  quit_delay_seconds = 10, -- seconds
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
