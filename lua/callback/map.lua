local map = require("callback.internal.map")

---Runs a iteratee functions for every element inside the collection **in parallel** to pass a new collection to result_callback. Passes the new mapped collection to result_callback. **Errors may stop the iteration early**
---@param collection any[] Collection of elements to pass as an argument to iteratee map function
---@param iteratee fun(element: any, callback: fun(err?: any, value?: boolean), index?: number, collection: any[]) A map function that runs with each element from the collection, can pass new value to final list on result_callback in parallel via its callback. When iteratee callback passes nil as result, the result gets converted to immutable & empty null objects to keep the table length intact in lua.
---@param result_callback fun(err: any, result: any[]) Result callback runs when **all iteratee functions run their callback** or **when one iteratee runs callback with error**. **Can be skipped when iteratee runs cancellation**
---@return any callback This will be changed to a Promise-like abstraction in the future
return function(collection, iteratee, result_callback)
  if type(iteratee) ~= "function" then
    return error('Callback.map(collection, iteratee, callback): Expected "iteratee" to be a function')
  end

  return map(math.huge, collection, iteratee, result_callback)
end
