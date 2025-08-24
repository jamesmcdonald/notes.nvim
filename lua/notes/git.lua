local Paths = require 'notes.paths'

local M = {}
---
--- Sync notes with git, committing and pushing if there are changes.
function M.sync_notes()
  local notesdir = Paths.getdir()
  if not notesdir then
    return
  end

  local msg = 'notes autocommit: ' .. os.date '%Y-%m-%d %H:%M:%S'

  local function notify(level, text)
    vim.schedule(function()
      vim.notify(text, level)
    end)
  end

  local function fail(cmd, res, extra)
    local detail = (res and res.stderr and res.stderr ~= '' and res.stderr) or (res and res.stdout) or ''
    if extra and extra ~= '' then
      detail = extra .. (detail ~= '' and ('\n' .. detail) or '')
    end

    notify(vim.log.levels.ERROR, ('Git failed (%s): %s'):format(table.concat(cmd, ' '), detail))
  end

  local function run(cmd, on_ok)
    vim.system(cmd, { cwd = notesdir }, function(res)
      if res.code ~= 0 then
        fail(cmd, res)
        return
      end
      if on_ok then
        on_ok(res)
      end
    end)
  end

  run({ 'git', 'rev-parse', '--is-inside-work-tree' }, function(res)
    if not res.stdout:match 'true' then
      fail({ 'git', 'rev-parse', '--is-inside-work-tree' }, res, 'Not a git repository in ' .. notesdir)
      return
    end

    run({ 'git', 'pull', '--rebase', '--autostash' }, function()
      run({ 'git', 'status', '--porcelain' }, function(st)
        local dirty = st.stdout ~= ''

        local function push()
          run({ 'git', 'push' }, function()
            notify(vim.log.levels.INFO, 'Notes: synced' .. (dirty and ' (pull, commit, push)' or ' (no local changes)'))
          end)
        end

        if not dirty then
          -- still push after rebase — there might be new local commits
          push()
          return
        end

        run({ 'git', 'add', '-A' }, function()
          run({ 'git', 'commit', '-m', msg }, function()
            push()
          end)
        end)
      end)
    end)
  end)
end

return M
