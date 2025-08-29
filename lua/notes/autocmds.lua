local M = {}
local GROUP = vim.api.nvim_create_augroup('NotesPlugin', { clear = true })

function M.apply()
  local cfg = require('notes.config').get()
  vim.api.nvim_clear_autocmds { group = GROUP }
  if cfg.auto_sync then
    vim.api.nvim_create_autocmd('BufWritePost', {
      group = GROUP,
      desc = 'Auto-sync notes on save',
      callback = function()
        if require('notes.paths').is_notes_buffer() then
          require('notes.git').sync_notes()
        end
      end,
    })

    vim.api.nvim_create_autocmd('BufEnter', {
      group = GROUP,
      desc = 'Pull changes on enter',
      callback = function()
        if require('notes.paths').is_notes_buffer() then
          require('notes.git').pull()
        end
      end,
    })

    vim.api.nvim_create_autocmd('FocusGained', {
      group = GROUP,
      desc = 'Pull changes on focus',
      callback = function()
        if require('notes.paths').is_notes_buffer() then
          require('notes.git').pull()
        end
      end,
    })
  end

  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = GROUP,
    desc = 'Wait for running git jobs on exit',
    callback = function()
      require('notes.git').quit_guard()
    end,
  })
end

return M
