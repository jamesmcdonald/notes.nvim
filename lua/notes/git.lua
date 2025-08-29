local state = {
  state = 'idle', -- 'idle', 'pulling', 'syncing'
  pending_sync = false,
  last_pull_ms = 0,
  debounce_pull_ms = 10 * 1000,
}

local M = {}

local function notify(level, text)
  vim.schedule(function()
    vim.notify(text, level)
  end)
end

local function now_ms()
  return vim.uv.now()
end

local function finish(do_checktime)
  if do_checktime then
    vim.schedule(function()
      vim.cmd.checktime()
    end)
  end
  state.last_pull_ms = now_ms()
  state.state = 'idle'
  if state.pending_sync then
    vim.schedule(function()
      state.pending_sync = false
      M.sync_notes()
    end)
  end
end

local function fail(cmd, res)
  local detail = (res and res.stderr and res.stderr ~= '' and res.stderr) or (res and res.stdout) or ''

  notify(vim.log.levels.ERROR, ('Git failed (%s): %s'):format(table.concat(cmd, ' '), detail))
  finish(false)
end

local function run(cmd, on_ok)
  local notesdir = require('notes.paths').getdir()
  if not notesdir then
    return
  end

  vim.system(
    cmd,
    { cwd = notesdir, text = true, env = { GIT_TERMINAL_PROMPT = '0', GIT_SSH_COMMAND = 'ssh -o BatchMode=yes' } },
    function(res)
      if res.code ~= 0 then
        fail(cmd, res)
        return
      end
      if on_ok then
        on_ok(res)
      end
    end
  )
end

--- Pull notes from git, debounced to avoid multiple simultaneous pulls.
function M.pull()
  if state.state == 'syncing' then
    return
  end
  if state.state == 'pulling' then
    return
  end
  if now_ms() - state.last_pull_ms < state.debounce_pull_ms then
    return
  end

  state.state = 'pulling'
  run({ 'git', 'rev-parse', '--is-inside-work-tree' }, function(res)
    if not res.stdout:match 'true' then
      fail({ 'git', 'rev-parse', '--is-inside-work-tree' }, res)
      return
    end
    run({ 'git', 'pull', '--rebase', '--autostash', '--quiet' }, function()
      notify(vim.log.levels.INFO, 'Notes: pulled')
      finish(true)
    end)
  end)
end

local function push_if_ahead(on_done)
  run({ 'git', 'rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}' }, function(up)
    local upstream = vim.trim(up.stdout or '')
    if upstream == '' then
      notify(vim.log.levels.WARN, 'Notes: no upstream configured, not pushing')
      if on_done then
        on_done(false)
        return
      end
    end

    run({ 'git', 'rev-list', '--left-right', '--count', upstream .. '...HEAD' }, function(count)
      local _, ahead = count.stdout:match '(%d+)%s+(%d+)'
      ahead = tonumber(ahead) or 0

      if ahead > 0 then
        run({ 'git', 'push', '--quiet' }, function()
          if on_done then
            on_done(true)
          end
        end)
      else
        if on_done then
          on_done(false)
        end
      end
    end)
  end)
end

--- Sync notes with git, committing and pushing if there are changes.
function M.sync_notes()
  if state.state == 'syncing' then
    return
  end
  if state.state == 'pulling' then
    state.pending_sync = true
    return
  end

  local msg = 'notes autocommit: ' .. os.date '%Y-%m-%d %H:%M:%S'

  state.state = 'syncing'

  run({ 'git', 'rev-parse', '--is-inside-work-tree' }, function(res)
    if not res.stdout:match 'true' then
      fail({ 'git', 'rev-parse', '--is-inside-work-tree' }, res)
      return
    end

    run({ 'git', 'pull', '--rebase', '--autostash', '--quiet' }, function()
      vim.schedule(function()
        vim.cmd.checktime()
      end)
      run({ 'git', 'status', '--porcelain' }, function(st)
        local dirty = st.stdout ~= ''

        local function push()
          push_if_ahead(function(pushed)
            if pushed then
              notify(
                vim.log.levels.INFO,
                dirty and 'Notes: synced (pull, commit, push)' or 'Notes: synced (pull, push)'
              )
            else
              notify(
                vim.log.levels.INFO,
                dirty and 'Notes: synced (pull, commit; no push)' or 'Notes: synced (pull only)'
              )
            end
            finish(false)
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

--- Guard to avoid quitting while a git operation is in progress.
function M.quit_guard()
  local cfg = require('notes.config').get()
  local ms = (cfg.quit_delay_seconds or 10) * 1000

  vim.notify('Notes: waiting for git to finish', vim.log.levels.INFO)
  vim.wait(ms, function()
    return state.state == 'idle' and not state.pending_sync
  end, 100)

  if state.pending_sync then
    state.pending_sync = false
    vim.notify('Notes: running pending sync before quit', vim.log.levels.INFO)
    M.sync_notes()
    vim.wait(ms, function()
      return state.state == 'idle'
    end, 100)
  end
end

return M
