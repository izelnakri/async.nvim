---Wraps the function in another function with callback parameter. Inside the wrapped function calls the provided function with provided arguments and callback as last
---@param ... any First parameter is function, the rest of the parameters to the first function inside the wrapped function
---@return any
return function(...)
  local arguments = { ... }

  if type(arguments[1]) ~= "function" then
    return error("First argument has to be a function!")
  end

  local func = table.remove(arguments, 1)

  return function(callback)
    return func(unpack(arguments), callback)
  end
end
