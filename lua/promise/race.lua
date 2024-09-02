return function(promises)
  local Promise = require("promise")

  return Promise:new(function(resolve, reject)
    local function handleResolution(value)
      if type(value) == "table" and type(value.and_then) == "function" then
        -- If the resolved value is a promise, continue racing with it
        value:and_then(handleResolution, reject)
      else
        -- Otherwise, resolve with the value
        resolve(value)
      end
    end

    local function handleRejection(reason)
      if type(reason) == "table" and type(reason.and_then) == "function" then
        -- If the rejection reason is a promise, continue racing with it
        reason:and_then(resolve, handleRejection)
      else
        -- Otherwise, reject with the reason
        reject(reason)
      end
    end

    for _, item in ipairs(promises) do
      if type(item) == "table" and type(item.and_then) == "function" then
        -- Handle promise-like objects
        item:and_then(handleResolution, handleRejection)
      else
        -- Resolve immediately if it's not a promise
        resolve(item)
        return
      end
    end
  end)
end
