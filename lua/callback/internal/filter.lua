local each_limit = require("callback.internal.each_limit")

return function(limit, collection, iteratee, callback)
  local collection_is_list = vim.isarray(collection)
  local truthValues = {}

  return each_limit(limit, collection, function(right, iterator_callback, left)
    iteratee(right, function(err, value)
      if value then
        if collection_is_list then
          table.insert(truthValues, right)
        else
          truthValues[left] = right
        end
      end

      iterator_callback(err)
    end, left)
  end, function(err)
    if err then
      return callback(err)
    end

    callback(err, truthValues)
  end)
end
