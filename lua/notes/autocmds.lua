local Config = require 'notes.config'
local Paths = require 'notes.paths'
local Git = require 'notes.git'

local M = {}
local GROUP = vim.api.nvim_create_augroup('NotesPlugin', { clear = true })

function M.apply()
  local cfg = Config.get()
  vim.api.nvim_clear_autocmds { group = GROUP }
  if cfg.auto_sync then
    vim.api.nvim_create_autocmd('BufWritePost', {
      group = GROUP,
      desc = 'Auto-sync notes on save',
      callback = function()
        if Paths.is_notes_buffer() then
          Git.sync_notes()
        end
      end,
    })

    vim.api.nvim_create_autocmd('BufEnter', {
      group = GROUP,
      desc = 'Pull changes on enter',
      callback = function()
        if Paths.is_notes_buffer() then
          Git.pull()
        end
      end,
    })

    vim.api.nvim_create_autocmd('FocusGained', {
      group = GROUP,
      desc = 'Pull changes on focus',
      callback = function()
        if Paths.is_notes_buffer() then
          Git.pull()
        end
      end,
    })
  end
end

return M
