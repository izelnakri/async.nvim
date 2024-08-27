local function settleNestedPromises(value)
  local Promise = require("promise")

  if type(value) == "table" and type(value.thenCall) == "function" then
    -- Handle promise-like objects
    return value
      :thenCall(function(resolvedValue)
        return settleNestedPromises(resolvedValue)
      end)
      :catch(function(reason)
        return { status = "rejected", reason = reason }
      end)
  elseif type(value) == "table" then
    -- Recursively resolve nested tables
    local keys = {}
    local promises = {}
    for k, v in pairs(value) do
      table.insert(keys, k)
      table.insert(promises, settleNestedPromises(v))
    end

    return Promise.all(promises):thenCall(function(resolvedValues)
      local settledTable = {}
      for i, key in ipairs(keys) do
        settledTable[key] = resolvedValues[i]
      end
      return settledTable
    end)
  else
    -- Return a resolved value directly
    return Promise.resolve(value)
  end
end

return function(hashTable)
  local Promise = require("promise")

  return Promise:new(function(resolve)
    local results = {}
    local remaining = 0

    for key, promise in pairs(hashTable) do
      remaining = remaining + 1

      settleNestedPromises(promise)
        :thenCall(function(resolvedValue)
          if resolvedValue.status == "fulfilled" or resolvedValue.status == "rejected" then
            results[key] = resolvedValue
          else
            results[key] = { status = "fulfilled", value = resolvedValue }
          end
          remaining = remaining - 1
          if remaining == 0 then
            resolve(results)
          end
        end)
        :catch(function(reason)
          results[key] = { status = "rejected", reason = reason }
          remaining = remaining - 1
          if remaining == 0 then
            resolve(results)
          end
        end)
    end

    if remaining == 0 then
      resolve(results)
    end
  end)
end
