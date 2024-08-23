require("async.test")

local dummy = { dummy = "dummy" }
local Promise = require("promise")
local Timers = require("timers")
local Helper = require("tests.promiseA+.helpers.init")

describe(
  "2.2.4: `onFulfilled` or `onRejected` must not be called until the execution context stack contains only platform code.",
  function()
    describe("`next` returns before the promise becomes fulfilled or rejected", function()
      Helper.test_fulfilled(async_it, dummy, function(promise, done)
        local thenHasReturned = false

        promise:thenCall(function()
          assert.is_true(thenHasReturned)
          done()
        end)

        thenHasReturned = true
      end)

      Helper.test_rejected(async_it, dummy, function(promise, done)
        local thenHasReturned = false

        promise:thenCall(nil, function()
          assert.is_true(thenHasReturned)
          done()
        end)

        thenHasReturned = true
      end)
    end)

    describe("Clean-stack execution ordering tests (fulfillment case)", function()
      it("when `onFulfilled` is added immediately before the promise is fulfilled", function()
        local promise, resolve = Promise.withResolvers()
        local onFulfilledCalled = false

        promise:thenCall(function()
          onFulfilledCalled = true
        end)

        resolve(dummy)

        assert.is_false(onFulfilledCalled)
      end)

      it("when `onFulfilled` is added immediately after the promise is fulfilled", function()
        local promise, resolve = Promise.withResolvers()
        local onFulfilledCalled = false

        resolve(dummy)

        promise:thenCall(function()
          onFulfilledCalled = true
        end)

        assert.is_false(onFulfilledCalled)
      end)

      async_it("when one `onFulfilled` is added inside another `onFulfilled`", function(done)
        local promise = Promise.resolve(dummy)
        local firstOnFulfilledFinished = false

        promise:thenCall(function()
          promise:thenCall(function()
            assert.is_true(firstOnFulfilledFinished)
            done()
          end)
          firstOnFulfilledFinished = true
        end)
      end)

      async_it("when `onFulfilled` is added inside an `onRejected`", function(done)
        local promise = Promise.reject(dummy)
        local promise2 = Promise.resolve(dummy)
        local firstOnRejectedFinished = false

        promise:thenCall(nil, function()
          promise2:thenCall(function()
            assert.is_true(firstOnRejectedFinished)
            done()
          end)
          firstOnRejectedFinished = true
        end)
      end)

      async_it("when the promise is fulfilled asynchronously", function(done)
        local promise, resolve = Promise.withResolvers()
        local firstStackFinished = false

        Timers.set_timeout(function()
          resolve(dummy)
          firstStackFinished = true
        end, 0)

        promise:thenCall(function()
          assert.is_true(firstStackFinished)
          done()
        end)
      end)
    end)

    describe("Clean-stack execution ordering tests (rejection case)", function()
      it("when `onRejected` is added immediately before the promise is rejected", function()
        local promise, _, reject = Promise.withResolvers()
        local onRejectedCalled = false

        promise:thenCall(nil, function()
          onRejectedCalled = true
        end)

        reject(dummy)

        assert.is_false(onRejectedCalled)
      end)

      it("when `onRejected` is added immediately after the promise is rejected", function()
        local promise, _, reject = Promise.withResolvers()
        local onRejectedCalled = false

        reject(dummy)

        promise:thenCall(nil, function()
          onRejectedCalled = true
        end)

        assert.is_false(onRejectedCalled)
      end)

      async_it("when `onRejected` is added inside an `onFulfilled`", function(done)
        local promise = Promise.resolve(dummy)
        local promise2 = Promise.reject(dummy)
        local firstOnFulfilledFinished = false

        promise:thenCall(function()
          promise2:thenCall(nil, function()
            assert.is_true(firstOnFulfilledFinished)
            done()
          end)
          firstOnFulfilledFinished = true
        end)
      end)

      async_it("when one `onRejected` is added inside another `onRejected`", function(done)
        local promise = Promise.reject(dummy)
        local firstOnRejectedFinished = false

        promise:thenCall(nil, function()
          promise:thenCall(nil, function()
            assert.is_true(firstOnRejectedFinished)
            done()
          end)
          firstOnRejectedFinished = true
        end)
      end)

      async_it("when the promise is rejected asynchronously", function(done)
        local promise, _, reject = Promise.withResolvers()
        local firstStackFinished = false

        Timers.set_timeout(function()
          reject(dummy)
          firstStackFinished = true
        end, 0)

        promise:thenCall(nil, function()
          assert.is_true(firstStackFinished)
          done()
        end)
      end)
    end)
  end
)
