local create_tester = require("callback.internal.create_tester")

---Runs a **truth test function** to every element inside the collection in parallel. **Stops the iteration when you pass truthy value inside iteratee**. **Errors may stop the iteration early**.
---@param collection any[] Collection of elements to pass as an argument to iteratee test function
---@param iteratee fun(element: any, callback: fun(err?: any, value?: boolean), index?: number, collection: any[]) A truth test to apply to each element **in parallel**.
---@param result_callback fun(err: any, result: true | false) Result callback runs when **any iteratee function passes truthy value** or **all iteratee functions pass their falsy value** in their callback. **Can be skipped when iteratee runs cancellation**
---@return any callback This will be changed to a Promise-like abstraction in the future
return function(collection, iteratee, result_callback)
  return create_tester(function(bool)
    return bool
  end, function(res)
    return res
  end, math.huge, collection, iteratee, result_callback)
end
