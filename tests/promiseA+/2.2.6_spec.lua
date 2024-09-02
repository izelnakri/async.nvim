require("async.test")

local Helper = require("tests.promiseA+.helpers.init")
local Timers = require("timers")
local spy = require("luassert.spy")

local dummy = { dummy = "dummy" }
local other = { other = "other" }

local sentinel = { sentinel = "sentinel" } -- a sentinel fulfillment value to test for with strict equality
local sentinel2 = { sentinel2 = "sentinel2" }
local sentinel3 = { sentinel3 = "sentinel3" }

local function callbackAggregator(times, ultimateCallback)
  local soFar = 0
  return function()
    soFar = soFar + 1

    if soFar == times then
      ultimateCallback()
    end
  end
end

describe("2.2.6: `next` may be called multiple times on the same promise.", function()
  describe(
    "2.2.6.1: If/when `promise` is fulfilled, all respective `onFulfilled` callbacks must execute in the order of their originating calls to `next`.",
    function()
      describe("multiple boring fulfillment handlers", function()
        Helper.test_fulfilled(async_it, sentinel, function(promise, done)
          local handler1 = spy.new(function()
            return other
          end)
          local handler2 = spy.new(function()
            return other
          end)
          local handler3 = spy.new(function()
            return other
          end)

          local rejected_spy = spy.new(function() end)
          promise:and_then(handler1, rejected_spy)
          promise:and_then(handler2, rejected_spy)
          promise:and_then(handler3, rejected_spy)

          promise:and_then(function(value)
            assert.are.equal(value, sentinel)

            assert.spy(handler1).was_called_with(sentinel)
            assert.spy(handler2).was_called_with(sentinel)
            assert.spy(handler3).was_called_with(sentinel)

            assert.spy(rejected_spy).was_not_called()

            done()
          end)
        end)
      end)

      describe("multiple fulfillment handlers, one of which throws", function()
        Helper.test_fulfilled(async_it, sentinel, function(promise, done)
          local handler1 = spy.new(function()
            return other
          end)
          local handler2 = spy.new(function()
            error(other)
          end)
          local handler3 = spy.new(function()
            return other
          end)

          local rejected_spy = spy.new(function() end)
          promise:and_then(handler1, spy)
          promise:and_then(handler2, spy)
          promise:and_then(handler3, spy)

          promise:and_then(function(value)
            assert.are.equal(value, sentinel)

            assert.spy(handler1).was_called_with(sentinel)
            assert.spy(handler2).was_called_with(sentinel)
            assert.spy(handler3).was_called_with(sentinel)

            assert.spy(rejected_spy).was_not_called()

            done()
          end)
        end)
      end)

      describe("results in multiple branching chains with their own fulfillment values", function()
        Helper.test_fulfilled(async_it, dummy, function(promise, done)
          local semiDone = callbackAggregator(3, done)

          promise
            :and_then(function()
              return sentinel
            end)
            :and_then(function(value)
              assert.are.equals(value, sentinel)

              semiDone()
            end)

          promise
            :and_then(function()
              error(sentinel2)
            end)
            :and_then(nil, function(reason)
              assert.are.equals(reason, sentinel2)

              semiDone()
            end)

          promise
            :and_then(function()
              return sentinel3
            end)
            :and_then(function(value)
              assert.are.equals(value, sentinel3)

              semiDone()
            end)
        end)
      end)

      describe("`onFulfilled` handlers are called in the original order", function()
        Helper.test_fulfilled(async_it, dummy, function(promise, done)
          local content = {}
          local ordered_callback = function(value)
            return function()
              table.insert(content, value)
            end
          end

          local handler1 = ordered_callback(1)
          local handler2 = ordered_callback(2)
          local handler3 = ordered_callback(3)

          promise:and_then(handler1)
          promise:and_then(handler2)
          promise:and_then(handler3)

          promise:and_then(function()
            assert.are.same(content, { 1, 2, 3 })
            done()
          end)
        end)

        describe("even when one handler is added inside another handler", function()
          Helper.test_fulfilled(async_it, dummy, function(promise, done)
            local content = {}
            local ordered_callback = function(value)
              return function()
                table.insert(content, value)
              end
            end

            local handler1 = ordered_callback(1)
            local handler2 = ordered_callback(2)
            local handler3 = ordered_callback(3)

            promise:and_then(function()
              handler1()
              promise:and_then(handler3)
            end)
            promise:and_then(handler2)

            promise:and_then(function()
              -- Give implementations a bit of extra time to flush their internal queue, if necessary.
              Timers.set_timeout(function()
                assert.are.same(content, { 1, 2, 3 })
                done()
              end, 15)
            end)
          end)
        end)
      end)
    end
  )

  describe(
    "2.2.6.2: If/when `promise` is rejected, all respective `onRejected` callbacks must execute in the order of their originating calls to `next`.",
    function()
      describe("multiple boring rejection handlers", function()
        Helper.test_rejected(async_it, sentinel, function(promise, done)
          local handler1 = spy.new(function()
            return other
          end)
          local handler2 = spy.new(function()
            return other
          end)
          local handler3 = spy.new(function()
            return other
          end)

          local fulfill_spy = spy.new(function() end)

          promise:and_then(fulfill_spy, handler1)
          promise:and_then(fulfill_spy, handler2)
          promise:and_then(fulfill_spy, handler3)

          promise:and_then(nil, function(reason)
            assert.are.equals(reason, sentinel)

            assert.spy(handler1).called_with(sentinel)
            assert.spy(handler2).called_with(sentinel)
            assert.spy(handler3).called_with(sentinel)
            assert.spy(fulfill_spy).was_not_called()

            done()
          end)
        end)
      end)

      describe("multiple rejection handlers, one of which throws", function()
        Helper.test_rejected(async_it, sentinel, function(promise, done)
          local handler1 = spy.new(function()
            return other
          end)
          local handler2 = spy.new(function()
            error(other)
          end)
          local handler3 = spy.new(function()
            return other
          end)

          local fulfill_spy = spy.new(function() end)
          promise:and_then(fulfill_spy, handler1)
          promise:and_then(fulfill_spy, handler2)
          promise:and_then(fulfill_spy, handler3)

          promise:and_then(nil, function(reason)
            assert.are.equals(reason, sentinel)

            assert.spy(handler1).called_with(sentinel)
            assert.spy(handler2).called_with(sentinel)
            assert.spy(handler3).called_with(sentinel)
            assert.spy(fulfill_spy).was_not_called()

            done()
          end)
        end)
      end)

      describe("results in multiple branching chains with their own fulfillment values", function()
        Helper.test_rejected(async_it, sentinel, function(promise, done)
          local semiDone = callbackAggregator(3, done)

          promise
            :and_then(nil, function()
              return sentinel
            end)
            :and_then(function(value)
              assert.are.equals(value, sentinel)
              semiDone()
            end)

          promise
            :and_then(nil, function()
              error(sentinel2)
            end)
            :and_then(nil, function(reason)
              assert.are.equals(reason, sentinel2)
              semiDone()
            end)

          promise
            :and_then(nil, function()
              return sentinel3
            end)
            :and_then(function(value)
              assert.are.equals(value, sentinel3)
              semiDone()
            end)
        end)
      end)

      describe("`onRejected` handlers are called in the original order", function()
        Helper.test_rejected(async_it, dummy, function(promise, done)
          local content = {}
          local ordered_callback = function(value)
            return function()
              table.insert(content, value)
            end
          end

          local handler1 = ordered_callback(1)
          local handler2 = ordered_callback(2)
          local handler3 = ordered_callback(3)

          promise:and_then(nil, handler1)
          promise:and_then(nil, handler2)
          promise:and_then(nil, handler3)

          promise:and_then(nil, function()
            assert.are.same(content, { 1, 2, 3 })
            done()
          end)
        end)

        describe("even when one handler is added inside another handler", function()
          Helper.test_rejected(async_it, dummy, function(promise, done)
            local content = {}
            local ordered_callback = function(value)
              return function()
                table.insert(content, value)
              end
            end

            local handler1 = ordered_callback(1)
            local handler2 = ordered_callback(2)
            local handler3 = ordered_callback(3)

            promise:and_then(nil, function()
              handler1()
              promise:and_then(nil, handler3)
            end)
            promise:and_then(nil, handler2)

            promise:and_then(nil, function()
              -- Give implementations a bit of extra time to flush their internal queue, if necessary.
              Timers.set_timeout(function()
                assert.are.same(content, { 1, 2, 3 })
                done()
              end, 15)
            end)
          end)
        end)
      end)
    end
  )
end)
