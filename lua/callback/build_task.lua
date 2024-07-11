local find_function_from_end = function(argument_list)
  for value in vim.iter(argument_list):rev() do
    if type(value) == "function" then
      return value
    end
  end
end

---@param sync_func fun(...) Makes a synchronous function a task without calling it, optionally applies parameters. Use Callback.apply for async functions. For error case specifications make them error(any, 0)
---@return fun(..., callback: fun) Returns a callback shaped asynchronous function. In future also returns promise
return function(sync_func, ...)
  local args = { ... }

  return function(...)
    local operation_arguments = { ... }
    local callback = find_function_from_end(operation_arguments)
    if not callback then
      error(
        "Wrong use of Callback.build_task(sync_function)(...): it is called on a line that shouldn't be a task or an iteratee function!"
      )
    end
    for _, value in pairs(operation_arguments) do
      if value ~= callback then
        args[#args + 1] = value
      end
    end

    local success, result_or_error = pcall(sync_func, unpack(args))
    if type(callback) == "function" then
      if success then
        callback(nil, result_or_error)
      else
        callback(result_or_error, nil)
      end
    end
  end
end
