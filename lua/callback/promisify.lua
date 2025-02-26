local Promise = require("promise")

---Runs a list or object of functions **in parallel** with a limit, it can pass its final values via their callbacks to result_callback. **Errors may stop the iteration early**
---@param task fun(any, fun)
---@return fun(...) This will be changed to a Promise-like abstraction in the future
return function(task)
  return function(...)
    local arguments = { ... }
    return Promise:new(function(resolve, reject)
      task(unpack(arguments), function(err, ...)
        if err then
          return reject(err)
        end

        return resolve(...)
      end)
    end)
  end
end
