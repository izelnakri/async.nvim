return function(inputs)
  local Promise = require("promise") -- Replace with your actual Promise module

  return Promise:new(function(resolve, reject)
    local results = {}
    local index = 1

    local function next()
      if index > #inputs then
        resolve(results) -- All functions have been executed successfully
      else
        local fn = inputs[index]
        index = index + 1

        local promise
        local status, err = pcall(function()
          promise = fn()
        end)

        if not status then
          reject(err) -- If a function doesn't return a promise or throws an error
          return
        end

        if type(promise) ~= "table" or type(promise.and_then) ~= "function" then
          reject("Promise.series: all functions must return a promise")
          return
        end

        promise
          :and_then(function(result)
            table.insert(results, result)
            next() -- Proceed to the next function in the series
          end)
          :catch(function(err)
            reject(err) -- Reject the whole series if any promise fails
          end)
      end
    end

    next() -- Start the series
  end)
end
