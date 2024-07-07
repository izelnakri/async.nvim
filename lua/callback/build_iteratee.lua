---An optional utility function that wraps your target function so its results can be passed to a result_callback. Optionally you can specify parameters during target_function call.
---@params target_function fun(param: any, callback?: fun(err: any, callback: fun(err: any, iterator_callback: any))) func has to be async and needs to handle a callback function internally
---@params ... any Parameteres one can pass to target_function during its call, passed parameters position is as follows: target_function(functions_first_param, passed_param_one, passed_param_two, functions_callback)
---@return fun(err: any, callback: fun(...), ...) iteratee Iteratee functions pass errors and values to a result_callback
return function(target_function, ...)
  local params_to_build = { ... }

  -- NOTE: param key has to be optional
  return function(param, callback, ...)
    local optional_params = unpack(vim.deepcopy(params_to_build))
    if optional_params then
      return target_function(param, optional_params, callback, function(...)
        return callback(...)
      end, ...)
    end

    return target_function(param, callback, function(...)
      return callback(...)
    end, ...)
  end
end
