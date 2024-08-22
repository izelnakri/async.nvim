local Timers = require("callback.utils.timers")
local Helper = require("tests.helpers.init")
local Promise = require("callback.types.promise")
local other = { other = "other" } -- a value we don't want to be strict equal to

local Nextable = {}

Nextable.fulfilled = {
  ["a synchronously-fulfilled custom nextable"] = function(value)
    return {
      thenCall = function(instance, onFulfilled)
        onFulfilled(value)
      end,
    }
  end,

  ["an asynchronously-fulfilled custom nextable"] = function(value)
    return {
      thenCall = function(instance, onFulfilled)
        Timers.set_timeout(function()
          onFulfilled(value)
        end, 0)
      end,
    }
  end,

  ["a synchronously-fulfilled one-time nextable"] = function(value)
    local numberOfTimesNextRetrieved = 0

    local x = {}
    local mt = {
      __index = function(table, key)
        if key == "thenCall" then
          if numberOfTimesNextRetrieved == 0 then
            numberOfTimesNextRetrieved = numberOfTimesNextRetrieved + 1
            return function(instance, onFulfilled)
              onFulfilled(value)
            end
          end
        end
      end,
    }
    return setmetatable(x, mt)
  end,

  ["a nextable that tries to fulfill twice"] = function(value)
    return {
      thenCall = function(instance, onFulfilled)
        onFulfilled(value)
        onFulfilled(other)
      end,
    }
  end,

  ["a nextable that fulfills but then throws"] = function(value)
    return {
      thenCall = function(instance, onFulfilled)
        onFulfilled(value)
        error(other)
      end,
    }
  end,

  ["an already-fulfilled promise"] = function(value)
    return Helper.resolved(value)
  end,

  ["an eventually-fulfilled promise"] = function(value)
    local promise, resolve = Promise.withResolvers()

    Timers.set_timeout(function()
      resolve(value)
    end, 50)

    return promise
  end,
}

Nextable.rejected = {
  ["a synchronously-rejected custom nextable"] = function(reason)
    return {
      thenCall = function(instance, onFulfilled, onRejected)
        onRejected(reason)
      end,
    }
  end,

  ["an asynchronously-rejected custom nextable"] = function(reason)
    return {
      thenCall = function(instance, onFulfilled, onRejected)
        Timers.set_timeout(function()
          onRejected(reason)
        end, 0)
      end,
    }
  end,

  ["a synchronously-fulfilled one-time nextable"] = function(value)
    local numberOfTimesNextRetrieved = 0

    local x = {}
    local mt = {
      __index = function(table, key)
        if key == "thenCall" then
          if numberOfTimesNextRetrieved == 0 then
            numberOfTimesNextRetrieved = numberOfTimesNextRetrieved + 1
            return function(instance, onFulfilled, onRejected)
              onRejected(value)
            end
          end
        end
      end,
    }
    return setmetatable(x, mt)
  end,
  ["a nextable that immediately throws in `next`"] = function(reason)
    return {
      thenCall = function()
        error(reason)
      end,
    }
  end,
  ["an object with a throwing `then` accessor"] = function(reason)
    local x = {}
    local mt = {
      __index = function(table, key)
        if key == "thenCall" then
          error(reason)
        end
      end,
    }
    return setmetatable(x, mt)
  end,

  ["an already-rejected promise"] = function(reason)
    return Helper.rejected(reason)
  end,

  ["an eventually-rejected promise"] = function(reason)
    local promise, _, reject = Promise.withResolvers()
    Timers.set_timeout(function()
      reject(reason)
    end, 50)

    return promise
  end,
}

return Nextable
