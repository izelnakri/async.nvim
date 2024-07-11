---In future: Runs the provided async function with arguments, returns a promise that awaits. It is basically a wrapper for the promise.
---@param func fun(any, fun)
---@param ...arguments Any arguments one provides to the func parameter
---@return table<any, any> promise In future this will be a
return function(func, ...)
  func(...)

  return {} -- NOTE: in future return a promise
end

-- turn sync function to async?
