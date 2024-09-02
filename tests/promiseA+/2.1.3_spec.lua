require("async.test")

local dummy = { dummy = "dummy" }
local Promise = require("promise")
local Timers = require("timers")
local spy = require("luassert.spy")
local Helper = require("tests.promiseA+.helpers.init")

describe("2.1.3.1: When rejected, a promise: must not transition to any other state.", function()
  Helper.test_rejected(async_it, dummy, function(promise, done)
    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    promise:and_then(fulfillment, rejection)

    Timers.set_timeout(function()
      assert.spy(rejection).was_called()
      assert.spy(fulfillment).was_not_called()
      done()
    end, 200)
  end)

  async_it("trying to reject then immediately fulfill", function(done)
    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    local promise, resolve, reject = Promise.with_resolvers()

    promise:and_then(fulfillment, rejection)

    reject(dummy)
    resolve(dummy)

    Timers.set_timeout(function()
      assert.spy(rejection).was_called()
      assert.spy(fulfillment).was_not_called()

      done()
    end, 100)
  end)

  async_it("trying to reject then fulfill, delayed", function(done)
    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    local promise, resolve, reject = Promise.with_resolvers()

    promise:and_then(fulfillment, rejection)

    Timers.set_timeout(function()
      reject(dummy)
      resolve(dummy)
    end, 50)

    Timers.set_timeout(function()
      assert.spy(rejection).was_called()
      assert.spy(fulfillment).was_not_called()
      done()
    end, 100)
  end)

  async_it("trying to reject immediately then fulfill delayed", function(done)
    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    local promise, resolve, reject = Promise.with_resolvers()

    promise:and_then(fulfillment, rejection)

    reject(dummy)

    Timers.set_timeout(function()
      resolve(dummy)
    end, 50)

    Timers.set_timeout(function()
      assert.spy(rejection).was_called()
      assert.spy(fulfillment).was_not_called()

      done()
    end, 100)
  end)
end)
