-- NOTE: Promise return for Callback method is REQUIRED because of Callback.filter play with promise functions
local Promise = {}

Promise.all = require("promise.all")
Promise.all_settled = require("promise.all_settled")
Promise.auto = require("promise.auto")
Promise.build_task = require("promise.build_task")
Promise.hash = require("promise.hash")
Promise.hash_settled = require("promise.hash_settled")
Promise.parallel = require("promise.parallel")
Promise.race = require("promise.race")
Promise.series = require("promise.series")
Promise.try_each = require("promise.try_each")
Promise.waterfall = require("promise.waterfall")

-- any, any_limit, any_series | every, limit options

Promise.new = require("promise.new")

function Promise:set_unhandlerd_rejection_handler(handler)
  self._unhandled_rejection_handler = handler
end

function Promise.resolve(value)
  return Promise:new(function(resolve)
    resolve(value)
  end)
end

function Promise.reject(reason)
  return Promise:new(function(_, reject)
    reject(reason)
  end)
end

function Promise.await(promise)
  local result
  local error_message
  local resolved = false
  local errored = false

  local function handleResolution(value)
    result = value
    resolved = true
  end

  local function handleRejection(reason)
    error_message = reason
    errored = true
  end

  promise:thenCall(handleResolution, handleRejection)

  -- Use vim.wait to periodically check the promise state
  while not resolved and not errored do
    vim.wait(10, function()
      -- Return false to continue waiting
      return resolved or errored
    end)
  end

  if errored then
    error(error_message)
  end

  return result
end

function Promise.with_resolvers()
  local resolve, reject
  local promise = Promise:new(function(res, rej)
    resolve = res
    reject = rej
  end)
  return promise, resolve, reject
end

return Promise

-- promise-async creates a async queue, I might also need that/good to have for RSVP/render waiters maybe, its like supervision chain
-- tostring values maybe
