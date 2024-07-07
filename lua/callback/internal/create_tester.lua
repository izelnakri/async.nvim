local break_loop = require("callback.internal.break_loop")
local each_limit = require("callback.internal.each_limit")

return function(check, get_result, limit, collection, iteratee, callback)
  local test_passed = false
  local test_result

  return each_limit(limit, collection, function(value, iteratee_callback, key)
    iteratee(value, function(err, result)
      if err or err == false then
        return iteratee_callback(err)
      elseif check(result) and not test_result then
        test_passed = true
        test_result = get_result(true)
        return iteratee_callback(nil, break_loop)
      end

      iteratee_callback()
    end, key)
  end, function(err)
    if err then
      return callback(err)
    elseif test_passed then
      return callback(nil, test_result)
    end

    callback(nil, get_result(false))
  end)
end
