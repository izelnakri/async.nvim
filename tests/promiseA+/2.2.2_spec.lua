require("async.test")

local dummy = { dummy = "dummy" }
local Promise = require("promise")
local Timers = require("timers")
local spy = require("luassert.spy")
local sentinel = { sentinel = "sentinel" }
local Helper = require("tests.promiseA+.helpers.init")

describe("2.2.2: If `onFulfilled` is a function,", function()
  describe(
    "2.2.2.1: it must be called after `promise` is fulfilled, with `promise`’s fulfillment value as its first argument.",
    function()
      Helper.test_fulfilled(it, sentinel, function(promise, done)
        promise:thenCall(function(value)
          assert.are.equal(value, sentinel)
          done()
        end)
      end)
    end
  )

  describe("2.2.2.2: it must not be called before `promise` is fulfilled", function()
    async_it("fulfilled after a delay", function(done)
      local promise, resolve = Promise.withResolvers()
      local fulfillment = spy.new(function() end)

      promise:thenCall(fulfillment)

      Timers.set_timeout(function()
        resolve(dummy)
      end, 50)

      Timers.set_timeout(function()
        assert.spy(fulfillment).was_called(1)
        done()
      end, 100)
    end)

    async_it("never fulfilled", function(done)
      local promise = Promise:new(function() end)
      local fulfillment = spy.new(function() end)

      promise:thenCall(fulfillment)

      Timers.set_timeout(function()
        assert.spy(fulfillment).was_not_called()
        done()
      end, 100)
    end)
  end)

  describe("2.2.2.3: it must not be called more than once.", function()
    async_it("already-fulfilled", function(done)
      local callback = spy.new(function() end)
      Promise.resolve(dummy):thenCall(callback)

      Timers.set_timeout(function()
        assert.spy(callback).was_called(1)
        done()
      end, 100)
    end)

    async_it("trying to fulfill a pending promise more than once, immediately", function(done)
      local promise, resolve = Promise.withResolvers()

      local callback = spy.new(function() end)
      promise:thenCall(callback)

      resolve(dummy)
      resolve(dummy)

      Timers.set_timeout(function()
        assert.spy(callback).was_called(1)
        done()
      end, 100)
    end)

    async_it("trying to fulfill a pending promise more than once, delayed", function(done)
      local promise, resolve = Promise.withResolvers()
      local callback = spy.new(function() end)

      promise:thenCall(callback)

      Timers.set_timeout(function()
        resolve(dummy)
        resolve(dummy)
      end, 50)

      Timers.set_timeout(function()
        assert.spy(callback).was_called(1)
        done()
      end, 100)
    end)

    async_it("trying to fulfill a pending promise more than once, immediately then delayed", function(done)
      local promise, resolve = Promise.withResolvers()

      local callback = spy.new(function() end)
      promise:thenCall(callback)

      resolve(dummy)

      Timers.set_timeout(function()
        resolve(dummy)
      end, 50)

      Timers.set_timeout(function()
        assert.spy(callback).was_called(1)
        done()
      end, 100)
    end)

    async_it("when multiple `next` calls are made, spaced apart in time", function(done)
      local promise, resolve = Promise.withResolvers()

      local callback_1 = spy.new(function() end)
      local callback_2 = spy.new(function() end)
      local callback_3 = spy.new(function() end)

      promise:thenCall(callback_1)

      Timers.set_timeout(function()
        promise:thenCall(callback_2)
      end, 50)

      Timers.set_timeout(function()
        promise:thenCall(callback_3)
      end, 100)

      Timers.set_timeout(function()
        resolve(dummy)
      end, 150)

      Timers.set_timeout(function()
        assert.spy(callback_1).was_called(1)
        assert.spy(callback_2).was_called(1)
        assert.spy(callback_3).was_called(1)
        done()
      end, 200)
    end)

    async_it("when `next` is interleaved with fulfillment", function(done)
      local promise, resolve = Promise.withResolvers()
      local callback_1 = spy.new(function() end)
      local callback_2 = spy.new(function() end)

      promise:thenCall(callback_1)
      resolve(dummy)
      promise:thenCall(callback_2)

      Timers.set_timeout(function()
        assert.spy(callback_1).was_called(1)
        assert.spy(callback_2).was_called(1)
        done()
      end, 100)
    end)
  end)
end)
