return function(tasks)
  local Promise = require("promise")

  return Promise:new(function(resolve, reject)
    local function next(index, previousResult)
      if index > #tasks then
        resolve(previousResult)
        return
      end

      local task = tasks[index]

      local status, result = pcall(function()
        return task(previousResult)
      end)

      if not status then
        reject(result)
      else
        if type(result) == "table" and type(result.thenCall) == "function" then
          result
            :thenCall(function(nextResult)
              next(index + 1, nextResult)
            end)
            :catch(function(err)
              reject(err)
            end)
        else
          reject("Promise.waterfall: all functions must return a promise")
        end
      end
    end

    next(1, nil) -- Start the chain with the first task and no initial value
  end)
end
