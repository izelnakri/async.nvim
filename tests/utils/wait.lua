return function(ms, callback)
  local should_stop_waiting = false

  callback = callback or function() end
  vim.defer_fn(function()
    callback()
    should_stop_waiting = true
    print("")
  end, ms)
  return vim.wait(ms + 100, function()
    return should_stop_waiting
  end, 0)
end
