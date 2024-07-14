local null = require("callback.types.null")
local only_once = require("callback.internal.only_once")
-- local get_tasks_type = require("callback.utils.get_tasks_type")

---Runs a list of task functions **in series** passes result of the callback of task to the next task until result_callback.
---@param tasks fun(callback: fun(err: any, value: any))[] Collection of tasks to pass result from one to another until result_callback.
---@param callback fun(err: any, result: any) Result callback runs when the final task runs with its callback or when any of the tasks runs the callback with error. **It can be skipped when iteratee runs cancellation**
---@return any callback This will be changed to a Promise-like abstraction in the future
return function(tasks, callback)
  if not vim.isarray(tasks) then
    return error(
      'Callback.waterfall(tasks, callback): Expected "tasks" to be a list! Because we cannot guarantee order of keys on iteration to pass arguments to one another'
    )
  elseif #tasks < 1 then
    return callback(nil, null)
  end

  local task_index = 0
  local next
  local next_task = function(...)
    local arguments = { ... }
    task_index = task_index + 1

    table.insert(arguments, only_once(next))
    tasks[task_index](unpack(arguments))
  end
  next = function(...)
    local arguments = { ... }
    local err = table.remove(arguments, 1)
    if err == false then
      return
    elseif err or task_index == #tasks then
      return callback and callback(err, unpack(arguments))
    end

    return next_task(unpack(arguments))
  end

  return next_task()
end
