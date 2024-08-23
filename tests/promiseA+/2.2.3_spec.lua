require("async.test")

local dummy = { dummy = "dummy" }
local Promise = require("promise")
local Timers = require("timers")
local spy = require("luassert.spy")
local sentinel = { sentinel = "sentinel" }
local Helper = require("tests.promiseA+.helpers.init")

describe("2.2.2: If `onRejected` is a function,", function()
  describe(
    "2.2.2.1: it must be called after `promise` is rejected, with `promise`’s rejection reason as its first argument.",
    function()
      Helper.test_rejected(async_it, sentinel, function(promise, done)
        promise:thenCall(nil, function(value)
          assert.are.equals(value, sentinel)
          done()
        end)
      end)
    end
  )

  describe("2.2.3.2: it must not be called before `promise` is rejected", function()
    async_it("rejected after a delay", function(done)
      local promise, _, reject = Promise.withResolvers()
      local rejection = spy.new(function() end)

      promise:thenCall(nil, rejection)

      Timers.set_timeout(function()
        reject(dummy)
      end, 50)

      Timers.set_timeout(function()
        assert.spy(rejection).was_called(1)
        done()
      end, 100)
    end)

    async_it("never rejected", function(done)
      local promise = Promise:new(function() end)
      local rejection = spy.new(function() end)

      promise:thenCall(nil, rejection)

      Timers.set_timeout(function()
        assert.spy(rejection).was_not_called()
        done()
      end, 150)
    end)
  end)

  describe("2.2.3.3: it must not be called more than once.", function()
    async_it("already-rejected", function(done)
      local callback = spy.new(function() end)
      Promise.reject(dummy):thenCall(nil, callback)

      Timers.set_timeout(function()
        assert.spy(callback).was_called(1)
        done()
      end, 100)
    end)

    async_it("trying to reject a pending promise more than once, immediately", function(done)
      local promise, _, reject = Promise.withResolvers()
      local callback = spy.new(function() end)

      promise:thenCall(nil, callback)

      reject(dummy)
      reject(dummy)

      Timers.set_timeout(function()
        assert.spy(callback).was_called(1)
        done()
      end, 100)
    end)

    async_it("trying to reject a pending promise more than once, delayed", function(done)
      local promise, _, reject = Promise.withResolvers()
      local callback = spy.new(function() end)

      promise:thenCall(nil, callback)

      Timers.set_timeout(function()
        reject(dummy)
        reject(dummy)
      end, 50)

      Timers.set_timeout(function()
        assert.spy(callback).was_called(1)
        done()
      end, 100)
    end)

    async_it("trying to reject a pending promise more than once, immediately then delayed", function(done)
      local promise, _, reject = Promise.withResolvers()

      local callback = spy.new(function() end)
      promise:thenCall(nil, callback)

      reject(dummy)

      Timers.set_timeout(function()
        reject(dummy)
      end, 50)

      Timers.set_timeout(function()
        assert.spy(callback).was_called(1)
        done()
      end, 100)
    end)

    async_it("when multiple `next` calls are made, spaced apart in time", function(done)
      local promise, _, reject = Promise.withResolvers()

      local callback_1 = spy.new(function() end)
      local callback_2 = spy.new(function() end)
      local callback_3 = spy.new(function() end)

      promise:thenCall(nil, callback_1)

      Timers.set_timeout(function()
        promise:thenCall(nil, callback_2)
      end, 50)

      Timers.set_timeout(function()
        promise:thenCall(nil, callback_3)
      end, 100)

      Timers.set_timeout(function()
        reject(dummy)
      end, 150)

      Timers.set_timeout(function()
        assert.spy(callback_1).was_called(1)
        assert.spy(callback_2).was_called(1)
        assert.spy(callback_3).was_called(1)
        done()
      end, 200)
    end)

    async_it("when `next` is interleaved with rejection", function(done)
      local promise, _, reject = Promise.withResolvers()
      local callback_1 = spy.new(function() end)
      local callback_2 = spy.new(function() end)

      promise:thenCall(nil, callback_1)
      reject(dummy)
      promise:thenCall(nil, callback_2)

      Timers.set_timeout(function()
        assert.spy(callback_1).was_called(1)
        assert.spy(callback_2).was_called(1)
        done()
      end, 100)
    end)
  end)
end)
