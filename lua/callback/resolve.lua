local find_function = function(argument_list)
  for value in vim.iter(argument_list):rev() do
    if type(value) == "function" then
      return value
    end
  end
end

---Create a callable task or iteratee function where the function always resolves/calls callback with provided arguments/values as a result
---@param ... any Arguments to pass as arguments to the callback
---@return fun(err: nil, value: any, ...) callback A callback function, useful for passing value around
return function(...)
  local params = { ... }

  return function(...)
    local args = { ... }
    local found_func = find_function(args)
    if not found_func then
      error(
        "Wrong use of Callback.resolve(x): it is called on a line that shouldn't be a task or an iteratee function!"
      )
    end
    return found_func(nil, unpack(params))
  end
end
