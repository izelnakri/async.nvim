local each_series = require("callback.each_series")
local once = require("callback.internal.once")

---Runs a list of task functions **in parallel** passes to the successful task to result callback.
---@param tasks fun(callback: fun(err: any, value: any))[] Collection of tasks to pass the first result to a callback
---@param callback? fun(err: any, result: any) Result callback runs with the first tasks result callback. **Can be skipped when iteratee runs cancellation**
---@return any callback This will be changed to a Promise-like abstraction in the future
return function(tasks, callback)
  callback = callback or function() end
  local final_error = nil
  local result

  return each_series(tasks, function(index, task, task_callback)
    task(function(...)
      local arguments = { ... }
      local err = table.remove(arguments, 1)

      if err == false then
        return task_callback(err)
        -- elseif #arguments < 3
      end

      if #arguments < 2 then
        result = arguments[1]
      else
        result = arguments
      end

      final_error = err
      if err then
        return task_callback(nil)
      end

      return task_callback({})
    end)
  end, function()
    if callback then
      return callback(final_error, result)
    end
  end)
end
