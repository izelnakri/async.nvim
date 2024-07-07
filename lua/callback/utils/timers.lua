Timers = {}

function Timers.set_interval(func, interval)
  local timer = vim.uv.new_timer()
  timer:start(interval, interval, function()
    func(interval)
  end)
  return timer
end

function Timers.set_timeout(func, timeout)
  timeout = timeout or 0
  local timer = vim.uv.new_timer()

  timer:start(timeout, 0, function()
    timer:stop()
    timer:close()
    func(timeout)
  end)
  return timer
end

function Timers.clear_interval(timer)
  timer:stop()
  timer:close()

  return timer
end

function Timers.clear_timeout(timer)
  timer:stop()
  timer:close()

  return timer
end

function Timers.track_time(callback)
  callback = callback or function() end
  local started_at = vim.uv.now()

  return {
    duration = nil,
    started_at = started_at,
    callback = callback,
    stop = function()
      callback(started_at)
      local stopped_at = vim.uv.now()

      return {
        duration = stopped_at - started_at,
        started_at = started_at,
        callback = callback,
        stopped_at = stopped_at,
      }
    end,
  }
end

return Timers
