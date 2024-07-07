local each_limit = require("callback.internal.each_limit")

---Builds up a value from by running iteratee function on every element inside the collection **in series, reversed**. Passes the last result to result_callback. **Errors may stop the iteration early**
---@param collection any[] | table<any, any> Collection of elements to pass as an argument to iteratee function
---@param iteratee fun(result: any, element: any, callback: fun(err?: any, value?: boolean), index?: number, collection: any[]) A function that runs with each element from the collection, can pass a value to result_callback in parallel, last run callback result gets passed to result_callback. Index value is index based on the original passed in collection.
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

  local is_list = vim.isarray(collection)
  local target_collection = (is_list and vim.iter(collection):rev():totable()) or collection
  return each_limit(1, target_collection, function(left, right, iterator_callback)
    local target_left = (function()
      if is_list then
        return #collection - left + 1
      end

      return left
    end)()

    iteratee(memo, right, function(err, result)
      memo = result
      iterator_callback(err)
    end, target_left, collection)
  end, function(err)
    return result_callback(err, memo)
  end)
end
