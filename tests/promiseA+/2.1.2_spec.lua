require("tests.async")

local dummy = { dummy = "dummy" }
local Promise = require("callback.types.promise")
local Timers = require("callback.utils.timers")
local spy = require("luassert.spy")
local Helper = require("tests.helpers.init")

describe("2.1.2.1: When fulfilled, a promise: must not transition to any other state.", function()
  Helper.test_fulfilled(async_it, dummy, function(promise, done)
    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    promise:thenCall(fulfillment, rejection)

    Timers.set_timeout(function()
      assert.spy(fulfillment).was_called()
      assert.spy(rejection).was_not_called()
      done()
    end, 200)
  end)

  async_it("trying to fulfill then immediately reject", function(done)
    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    local promise, resolve, reject = Promise.withResolvers()

    promise:thenCall(fulfillment, rejection)

    resolve(dummy)
    reject(dummy)

    Timers.set_timeout(function()
      assert.spy(fulfillment).was_called()
      assert.spy(rejection).was_not_called()
      done()
    end, 100)
  end)

  async_it("trying to fulfill then reject, delayed", function(done)
    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    local promise, resolve, reject = Promise.withResolvers()

    promise:thenCall(fulfillment, rejection)

    Timers.set_timeout(function()
      resolve(dummy)
      reject(dummy)
    end, 50)

    Timers.set_timeout(function()
      assert.spy(fulfillment).was_called()
      assert.spy(rejection).was_not_called()

      done()
    end, 100)
  end)

  async_it("trying to fulfill immediately then reject delayed", function(done)
    local fulfillment = spy.new(function() end)
    local rejection = spy.new(function() end)

    local promise, resolve, reject = Promise.withResolvers()

    promise:thenCall(fulfillment, rejection)

    resolve(dummy)

    Timers.set_timeout(function()
      reject(dummy)
    end, 50)

    Timers.set_timeout(function()
      assert.spy(fulfillment).was_called()
      assert.spy(rejection).was_not_called()

      done()
    end, 100)
  end)
end)
