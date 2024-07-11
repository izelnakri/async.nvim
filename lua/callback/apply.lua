---Creates a continuation function with some arguments already applied to *any* function. Useful as a shorthand for tasks or iteratees. Any arguments speficied after the function gets applied to the function from left when function is called.
---@params target_function fun(param: any, callback?: fun(err: any, callback: fun(err: any, iterator_callback: any))) func has to be async and needs to handle a callback function internally
---@params ... any Parameters one can pass to target_function during its call, passed parameters position is as follows: target_function(functions_first_param, passed_param_one, passed_param_two, functions_callback)
---@return fun(...) iteratee Iteratee functions pass errors and values to a result_callback
return function(target_function, ...)
  local args = { ... }
  return function(...)
    local all_args = {}
    for index = 1, #args do
      all_args[index] = args[index]
    end
    for index = 1, select("#", ...) do
      all_args[#args + index] = select(index, ...)
    end

    return target_function(unpack(all_args))
  end
end
