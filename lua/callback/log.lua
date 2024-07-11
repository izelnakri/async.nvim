---Immediately runs the task and logs the result or error on console
---@params task fun(..., callback: fun) Task to run
---@params ... any Parameters to pass to the task
return function(task, ...)
  return task(..., function(err, result)
    if err then
      vim.print("ERR:", vim.inspect(err))
    else
      vim.print(vim.inspect(result))
    end
  end)
end
