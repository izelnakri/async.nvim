-- NOTE: Promise return for Callback method is REQUIRED because of Callback.filter play with promise functions
local Promise = {}

Promise.all = require("promise.all")
Promise.all_settled = require("promise.all_settled")
Promise.hash = require("promise.hash")
Promise.hash_settled = require("promise.hash_settled")
Promise.race = require("promise.race")
Promise.try_each = require("promise.try_each")

-- Promise.curry?
-- Promise.auto? -> complex but very useful
-- Promise.apply then others: -> instead func.pipe
-- series, waterfall, parallel, parallel, limit | all can accept normal values, parallel only accepts promises
-- Promise.auto

-- any, any_limit, any_series | every

Promise.new = require("promise.new")

function Promise:setUnhandledRejectionHandler(handler)
  self._unhandledRejectionHandler = handler
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
  local co = coroutine.create(function()
    local value
    local done = false

    promise:thenCall(function(result)
      value = result
      done = true
    end, function(err)
      value = err
      done = true
    end)

    while not done do
      coroutine.yield()
    end

    return value
  end)

  local _, result = coroutine.resume(co)
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
