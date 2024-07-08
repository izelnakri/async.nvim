local each_limit = require("callback.internal.each_limit")

return function(limit, collection, iteratee, callback)
  if not vim.isarray(collection) then
    return error("Callback.map functions can only be called on list collections!")
  end

  local result = {}
  return each_limit(limit, collection, function(right, iterator_callback, left)
    iteratee(right, function(err, value)
      table.insert(result, value)

      iterator_callback(err)
    end, left, collection)
  end, function(err)
    if err then
      return callback(err, result)
    end

    callback(err, result)
  end)
end
