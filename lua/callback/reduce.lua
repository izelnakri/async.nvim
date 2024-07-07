local each_limit = require("callback.internal.each_limit")

---Builds up a value from by running iteratee function on every element inside the collection **in series**. Passes the last result to result_callback. **Errors may stop the iteration early**
---@param collection any[] | table<any, any> Collection of elements to pass as an argument to iteratee function
---@param iteratee fun(result: any, element: any, callback: fun(err?: any, value?: boolean), index?: number, collection: any[]) A function that runs with each element from the collection, can pass a value to result_callback in parallel, last run callback result gets passed to result_callback.
---@param result_callback fun(err: any, result: any) Result callback runs when final result gets built up by all iteratees finished running their callback or **when one iteratee runs callback with error or cancellation**. **Can be skipped when any iteratee runs cancellation**
---@return any callback This will be changed to a Promise-like abstraction in the future
return function(collection, memo, iteratee, result_callback)
  if type(iteratee) ~= "function" then
    return error('Callback.reduce(collection, result, iteratee, callback): Expected "iteratee" to be a function')
  end

  if iteratee == nil then
    iteratee = memo
    memo = nil
  end

  return each_limit(1, collection, function(right, iterator_callback, left)
    iteratee(memo, right, function(err, result)
      memo = result
      iterator_callback(err)
    end, left, collection)
  end, function(err)
    return result_callback(err, memo)
  end)
end
