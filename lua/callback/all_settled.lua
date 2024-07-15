local List = require("callback.utils.list")
local each_limit = require("callback.internal.each_limit")
local null = require("callback.types.null")

local function get_task_results(arguments)
  if #arguments < 2 then
    return (arguments[1] == nil and null) or arguments[1]
  end

  local result = {}
  for index, value in ipairs(arguments) do
    result[index] = (value == nil and null) or value
  end

  return result
end

local function expand_returned_list(operation_results, operation_indexes, initial_list, fill_function)
  return List.reduce(initial_list, function(result, initial_value, index)
    local operation_index = List.index_of(operation_indexes, index)
    if operation_index then
      local operation_result = operation_results[operation_index]

      return List.add(result, (operation_result == nil and null) or operation_result)
    end

    return List.add(result, fill_function(initial_value))
  end, {})
end

---Runs a collection of tasks and passes them to result_callback, waits for the settlement of *all* tasks, whether they are successfull or with error.
---@param initial_list any[] A collection of values and/or task functions to run
---@param final_callback? fun(err: any[], result: any[]) Result callback runs when all tasks run their callback with or without error. **Can be skipped upon cancellation**
---@return any callback This will be changed to a Promise-like abstraction in the future
return function(initial_list, final_callback)
  if not vim.isarray(initial_list) then
    return error('Callback.all_settled(initial_list, callback): Expected "initial_list" to be a list!')
  end

  local tasks, task_indexes = unpack(List.reduce(initial_list, function(result, value, index)
    if type(value) == "function" then
      List.push(result[1], value)
      List.push(result[2], index)
    end

    return result
  end, { {}, {} }))
  local errors, results = {}, {}

  return each_limit(math.huge, tasks, function(task, task_callback, key)
    task(function(...)
      local arguments = { ... }
      local error = table.remove(arguments, 1)

      errors[key] = (error == nil and null) or error
      results[key] = get_task_results(arguments)

      if errors[key] == false then
        return task_callback(false)
      end

      task_callback()
    end)
  end, function()
    if final_callback then
      return final_callback(
        expand_returned_list(errors, task_indexes, initial_list, function()
          return null
        end),
        expand_returned_list(results, task_indexes, initial_list, function(value)
          return value
        end)
      )
    end
  end)
end
