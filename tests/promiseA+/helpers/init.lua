local Promise = require("promise")
local Timers = require("timers")

local dummy = { dummy = "dummy" } -- we fulfill or reject with this when we don't intend to test against it

local Helper = {}

--generate a pre-resolved promise
Helper.resolved = function(value)
  return Promise:new(function(res)
    res(value)
  end)
end

--generate a pre-rejected promise
Helper.rejected = function(reason)
  return Promise:new(function(res, rej)
    rej(reason)
  end)
end

Helper.test_fulfilled = function(it, value, test)
  it("already-fulfilled", function(done)
    test(Helper.resolved(value), done)
  end)

  it("immediately-fulfilled", function(done)
    local promise, resolve = Promise.with_resolvers()
    test(promise, done)
    resolve(value)
  end)

  it("eventually-fulfilled", function(done)
    local promise, resolve = Promise.with_resolvers()
    test(promise, done)

    Timers.set_timeout(function()
      resolve(value)
    end, 50)
  end)
end

Helper.test_rejected = function(it, reason, test)
  it("already-rejected", function(done)
    test(Helper.rejected(reason), done)
  end)

  it("immediately-rejected", function(done)
    local promise, _, reject = Promise.with_resolvers()
    test(promise, done)
    reject(reason)
  end)

  it("eventually-rejected", function(done)
    local promise, _, reject = Promise.with_resolvers()

    test(promise, done)

    Timers.set_timeout(function()
      reject(reason)
    end, 50)
  end)
end

Helper.reasons = {
  ["`nil`"] = function()
    return nil
  end,
  ["`false`"] = function()
    return false
  end,
  ["`0`"] = function()
    return 0
  end,
  ["an error"] = function()
    error()
  end,
  ["a table"] = function()
    return {}
  end,
  ["an always-pending nextable"] = function()
    return { and_then = function() end }
  end,
  ["a fulfilled promise"] = function()
    return Helper.resolved(dummy)
  end,
  ["a rejected promise"] = function()
    return Helper.rejected(dummy)
  end,
}

return Helper
