return function(list)
  local Promise = require("promise")

  return Promise:new(function(resolve, reject)
    local results = {}
    local remaining = #list
    local settled = false

    if remaining == 0 then
      resolve(results)
      return
    end

    local function check_completion()
      if remaining == 0 and not settled then
        resolve(results)
      end
    end

    for i, item in ipairs(list) do
      if type(item) == "table" and type(item.thenCall) == "function" then
        item
          :thenCall(function(value)
            results[i] = value
            remaining = remaining - 1
            check_completion()
          end)
          :catch(function(reason)
            if not settled then
              settled = true
              reject(reason)
            end
          end)
      else
        results[i] = item
        remaining = remaining - 1
        check_completion()
      end
    end
  end)
end
