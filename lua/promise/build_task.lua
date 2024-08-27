---@param promise_returning_func fun(...) Asynchronous function that returns a promise, target function to apply additional parameters
---@return fun(...): _ Function that can be called with curried parameters, returns a Promise. Useful for Promise.waterfall, Promise.series etc
return function(promise_returning_func, ...)
  local initial_arguments = { ... }

  return function(...)
    local target_arguments = {}
    local last_provided_arguments = { ... }

    for _, arg in pairs(initial_arguments) do
      target_arguments[#target_arguments + 1] = arg
    end
    for _, arg in pairs(last_provided_arguments) do
      target_arguments[#target_arguments + 1] = arg
    end

    local result = promise_returning_func(unpack(target_arguments))
    if type(result) == "table" and type(result.thenCall) == "function" then
      return result
    end

    error("Promise.build_task(func): only accepts functions that return a promise!")
  end
end
