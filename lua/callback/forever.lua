local only_once = require("callback.internal.only_once")

---Runs a function that accepts **a callback as a first parameter**, **indefinitely** unless cancelled or errored out. If function runs a callback(err, result) with error it stops iteration and runs the error_callback.
---@param target_function fun(callback: fun(error: any, result: any): any) Collection of elements to pass as an argument to iteratee function
---@param error_callback? fun(err: any, result: any[]) Error callback only runs if the **target_function** runs a callback(err) with error
---@return any callback This will be changed to a Promise-like abstraction in the future
return function(target_function, error_callback)
  if type(target_function) ~= "function" then
    return error("Callback.forever(func, err_callback): 'func' is not a function!")
  end

  local done = only_once(error_callback or function() end)

  local next_func
  next_func = function(err)
    if err then
      return done(err)
    elseif err == false then
      return
    end

    return vim.schedule(function()
      return target_function(next_func)
    end)
  end

  return next_func()
end
