return function(tasks)
  local Promise = require("promise")

  return Promise:new(function(resolve, reject)
    if #tasks == 0 then
      return resolve({})
    end

    local results = {}
    local remaining = #tasks
    local has_rejected = false

    for i, task in ipairs(tasks) do
      local result = task()

      if type(result) ~= "table" or type(result.thenCall) ~= "function" then
        return reject("Promise.parallel: all functions must return a promise")
      end

      result
        :thenCall(function(value)
          if has_rejected then
            return
          end
          results[i] = value
          remaining = remaining - 1
          if remaining == 0 then
            resolve(results)
          end
        end)
        :catch(function(err)
          if not has_rejected then
            has_rejected = true
            reject(err)
          end
        end)
    end
  end)
end
