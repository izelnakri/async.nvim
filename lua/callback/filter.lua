local filter = require("callback.internal.filter")

---Runs a truth test iteratee filter function with every element inside the collection **in parallel**. Passes the filtered result to result_callback. **Errors may stop the iteration early**
---@param collection any[] Collection of elements to pass as an argument to iteratee function
---@param iteratee fun(element: any, callback: fun(err?: any, value?: boolean), index?: number, collection: any[]) A filter function that runs with each element from the collection, can pass a truthy or falsy value to result_callback in parallel via its callback.
---@param result_callback? fun(err: any, result: any[]) Result callback runs when **all iteratee functions run their callback** or **when one iteratee runs callback with error**. **Can be skipped when iteratee runs cancellation**
---@return any callback This will be changed to a Promise-like abstraction in the future
return function(collection, iteratee, result_callback)
  if type(iteratee) ~= "function" then
    return error('Callback.filter(collection, iteratee, callback): Expected "iteratee" to be a function')
  end

  return filter(math.huge, collection, iteratee, result_callback)
end
