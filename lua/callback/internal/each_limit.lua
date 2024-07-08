local iterator = require("callback.internal.iterator")
local once = require("callback.internal.once")
local only_once = require("callback.internal.only_once")
local break_loop = require("callback.internal.break_loop")
local null = require("callback.internal.null")

return function(concurrency_limit, obj, iteratee, result_callback)
  result_callback = once(result_callback)

  if concurrency_limit <= 0 then
    return error("concurrencyLimit cannot be less than 1")
  elseif not obj then
    return result_callback(nil, null) -- Early termination if there is no obj
  end

  local next_element = iterator(obj)
  local done = false
  local canceled = false
  local running = 0
  local looping = false -- NOTE: This check is a stack overflow optimization on very large collections
  local last_result
  local replenish

  local iteratee_callback = function(err, result)
    if canceled then
      return
    end

    running = running - 1
    last_result = (result == nil and null) or result

    if err then
      done = true
      return result_callback(err)
    elseif err == false then -- NOTE: This is cancel case, never leads to result_callback
      done = true
      canceled = true
    elseif result == break_loop or (done and running == 0) then -- NOTE: This short-circuiting, leads to result_callback
      done = true
      return result_callback(nil, last_result)
    elseif not looping then
      return replenish()
    end
  end

  replenish = function()
    looping = true

    while running < concurrency_limit and not done do
      local elem = next_element()
      if elem == nil then
        done = true

        if running == 0 then
          result_callback(nil, last_result) -- NOTE: moves to result_callback
        end

        return
      end

      running = running + 1

      iteratee(elem.right, only_once(iteratee_callback), elem.left, obj)
    end

    looping = false
  end

  replenish()
end
