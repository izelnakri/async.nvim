return function(list)
  local Promise = require("promise")

  return Promise:new(function(resolve)
    local results = {}
    local remaining = #list

    if remaining == 0 then
      resolve(results)
      return
    end

    local function settle(status, index, value)
      results[index] = { status = status, value = value }
      remaining = remaining - 1
      if remaining == 0 then
        resolve(results)
      end
    end

    for i, item in ipairs(list) do
      if type(item) == "table" and type(item.thenCall) == "function" then
        item:thenCall(function(value)
          if type(value) == "table" and type(value.thenCall) == "function" then
            value:thenCall(function(resolvedValue)
              settle("fulfilled", i, resolvedValue)
            end, function(reason)
              settle("rejected", i, reason)
            end)
          else
            settle("fulfilled", i, value)
          end
        end, function(reason)
          settle("rejected", i, reason)
        end)
      else
        settle("fulfilled", i, item)
      end
    end
  end)
end
