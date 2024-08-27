local function resolveNestedPromises(value)
  local Promise = require("promise")

  if type(value) == "table" and type(value.thenCall) == "function" then
    -- If the value is a promise, resolve it and recursively resolve any nested values
    return value:thenCall(resolveNestedPromises)
  elseif type(value) == "table" then
    -- If the value is a table, recursively resolve all its entries
    local keys = {}
    local promises = {}
    for k, v in pairs(value) do
      table.insert(keys, k)
      table.insert(promises, resolveNestedPromises(v))
    end

    return Promise.all(promises):thenCall(function(resolvedValues)
      local resolvedTable = {}
      for i, key in ipairs(keys) do
        resolvedTable[key] = resolvedValues[i]
      end
      return resolvedTable
    end)
  else
    -- If the value is not a promise or table, resolve it directly
    return Promise.resolve(value)
  end
end

return function(hashTable)
  local Promise = require("promise")

  return Promise:new(function(resolve, reject)
    local results = {}
    local remaining = 0

    for key, promise in pairs(hashTable) do
      remaining = remaining + 1
      resolveNestedPromises(promise)
        :thenCall(function(value)
          results[key] = value
          remaining = remaining - 1
          if remaining == 0 then
            resolve(results)
          end
        end)
        :catch(function(reason)
          reject(reason)
        end)
    end

    -- Handle the case where the table is empty
    if remaining == 0 then
      resolve(results)
    end
  end)
end
