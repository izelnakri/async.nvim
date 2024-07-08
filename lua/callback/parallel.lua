local each_limit = require("callback.internal.each_limit")
local get_tasks_type = require("callback.utils.get_tasks_type")
local null = require("callback.internal.null")

local get_task_results = function(arguments)
  if #arguments < 2 then
    return (arguments[1] == nil and null) or arguments[1]
  end

  local result = {}
  for index, value in ipairs(arguments) do
    result[index] = (value == nil and null) or value
  end

  return result
end

-- NOTE: check diff from internal/map and abstract it away if needed:

---Runs a list or object of functions **in parallel**, it can pass its final values via their callbacks to result_callback. **Errors may stop the iteration early**
---@param tasks function[] | table<any, function> Collection of functions to pass as a result to result_callback. When tasks callback passes nil as result, the result gets converted to immutable & empty null objects to keep the table length intact in lua.
---@param result_callback? fun(err: any, result: any[] | table<any, function>) Result callback runs when **all parallel functions run their callback** or **when one iteratee runs callback with error**. **Can be skipped when iteratee runs cancellation**
---@return any callback This will be changed to a Promise-like abstraction in the future
return function(tasks, result_callback)
  local tasks_type = get_tasks_type(tasks)
  if tasks_type == nil then
    return error('Callback.parallel(tasks, callback): Expected "tasks" to be a list or an object')
  end

  local results = {}

  return each_limit(math.huge, tasks, function(task, task_callback, key)
    task(function(...)
      local arguments = { ... }
      local err = table.remove(arguments, 1)

      results[key] = get_task_results(arguments)

      task_callback(err)
    end)
  end, function(err)
    if result_callback then
      return result_callback(err, results)
    end
  end)
end
