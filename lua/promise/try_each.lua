local function try_each(promises)
  local Promise = require("promise")

  return Promise:new(function(resolve, reject)
    local index = 1
    local lastError

    local function tryNext()
      if index > #promises then
        -- If we've tried all promises and none resolved, reject with the last error
        reject(lastError)
        return
      end

      local currentPromise = promises[index]
      index = index + 1

      currentPromise
        :thenCall(function(value)
          -- Resolve as soon as the first promise resolves
          resolve(value)
        end)
        :catch(function(reason)
          -- Store the error and try the next promise
          lastError = reason
          tryNext()
        end)
    end

    -- Start the sequence
    if #promises > 0 then
      tryNext()
    else
      -- If the list is empty, reject immediately
      reject("No promises to try.")
    end
  end)
end

return try_each
