local map = require("callback.internal.map")

---Runs the iteratee function with amount of times provided as count **in series**. Passes the results in iteratee callbacks to result_callback. **Errors may stop the iteration early**
---@param count number Number of times to run the iteratee function. When iteratee callback passes nil as result, the result gets converted to immutable & empty null objects to keep the result table length intact in lua.
---@param iteratee fun(index: number, callback: fun(err?: any, value?: boolean), index_list: number[]) A function that runs with each element from the collection, can pass a value to result_callback in series, last run callback result gets passed to result_callback.
---@param result_callback? fun(err: any, result: any[]) Result callback runs when **all iteratee functions run their callback** or **when one iteratee runs callback with error**. **Can be skipped when iteratee runs cancellation**
---@return any callback This will be changed to a Promise-like abstraction in the future
return function(count, iteratee, result_callback)
  if type(iteratee) ~= "function" then
    return error('Callback.map(collection, iteratee, callback): Expected "iteratee" to be a function')
  end

  local list = {}
  local results = {}
  for i = 1, count do
    table.insert(list, i)
  end

  return map(1, list, function(index, iterator_callback)
    iteratee(index, function(err, result)
      table.insert(results, result)
      return iterator_callback(err)
    end, list)
  end, function(err)
    if result_callback then
      return result_callback(err, results)
    end
  end)
end
