local once = require("callback.internal.once")

---Runs a list functions **in parallel** passes to the result_callback the first one that settles, calls its callback with result or error.
---@param tasks fun(callback: fun(err: any, value: any))[] Collection of tasks to pass the first error or result to a callback
---@param callback? fun(err: any, result: any) Result callback runs with the result or error of the **first settling task** that runs its callback.
---@return any callback This will be changed to a Promise-like abstraction in the future
return function(tasks, callback)
  callback = once(callback) -- NOTE: VERY IMPORTANT HERE

  if not vim.isarray(tasks) then
    return error("First argument to race must be an array of functions")
  elseif #tasks == 0 then
    return callback()
  end

  for i in ipairs(tasks) do
    tasks[i](callback)
  end
end
