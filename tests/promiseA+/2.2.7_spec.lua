require("async.test")

local Helper = require("tests.promiseA+.helpers.init")
local Promise = require("promise")
local Timers = require("timers")

local dummy = { dummy = "dummy" } -- we fulfill or reject with this when we don't intend to test against it
local sentinel = { sentinel = "sentinel" } -- a sentinel fulfillment value to test for with strict equality
local other = { other = "other" } -- a value we don't want to be strict equal to

describe("2.2.7: `next` must return a promise: `promise2 = promise1:next(onFulfilled, onRejected)`", function()
  it("is a promise", function()
    local promise1 = Promise:new(function() end)
    local promise2 = promise1:and_then()

    assert.are.same(type(promise2), "table")
    assert.are.same(type(promise2.and_then), "function")
  end)

  describe(
    "2.2.7.1: If either `onFulfilled` or `onRejected` returns a value `x`, run the Promise Resolution Procedure `[[Resolve]](promise2, x)`",
    function()
      it("see separate 3.3 tests", function() end)
    end
  )

  describe(
    "2.2.7.2: If either `onFulfilled` or `onRejected` throws an exception `e`, `promise2` must be rejected with `e` as the reason.",
    function()
      local function testReason(expectedReason, stringRepresentation)
        describe("The reason is " .. stringRepresentation, function()
          Helper.test_fulfilled(async_it, dummy, function(promise1, done)
            local promise2 = promise1:and_then(function()
              error(expectedReason)
            end)

            promise2:and_then(nil, function(actualReason)
              assert.are.equals(actualReason, expectedReason)
              done()
            end)
          end)

          Helper.test_rejected(async_it, dummy, function(promise1, done)
            local promise2 = promise1:and_then(nil, function()
              error(expectedReason)
            end)

            promise2
              :and_then(nil, function(actualReason)
                assert.are.equals(actualReason, expectedReason)
                done()
              end)
              :catch(print)
          end)
        end)
      end

      for stringRepresentation, callback in pairs(Helper.reasons) do
        testReason(callback, stringRepresentation)
      end
    end
  )
end)

describe(
  "2.2.7.3: If `onFulfilled` is not a function and `promise1` is fulfilled, `promise2` must be fulfilled with the same value.",
  function()
    local function testNonFunction(nonFunction, stringRepresentation)
      describe("`onFulfilled` is " .. stringRepresentation, function()
        Helper.test_fulfilled(async_it, sentinel, function(promise1, done)
          Timers.set_timeout(function()
            local promise2 = promise1:and_then(nonFunction)

            promise2
              :and_then(function(value)
                assert.are.equals(value, sentinel)
                done()
              end)
              :catch(print)
          end, 100)
        end)
      end)
    end

    testNonFunction(nil, "`nil`")
    testNonFunction(false, "`false`")
    testNonFunction(5, "`5`")
    testNonFunction({}, "a table")
    testNonFunction({
      function()
        return other
      end,
    }, "an array containing a function")
  end
)

describe(
  "2.2.7.4: If `onRejected` is not a function and `promise1` is rejected, `promise2` must be rejected with the same reason.",
  function()
    local function testNonFunction(nonFunction, stringRepresentation)
      describe("`onRejected` is " .. stringRepresentation, function()
        Helper.test_rejected(async_it, sentinel, function(promise1, done)
          local promise2 = promise1:and_then(nil, nonFunction)

          promise2:and_then(nil, function(reason)
            assert.are.equals(reason, sentinel)
            done()
          end)
        end)
      end)
    end

    testNonFunction(nil, "`nil`")
    testNonFunction(false, "`false`")
    testNonFunction(5, "`5`")
    testNonFunction({}, "a table")
    testNonFunction({
      function()
        return other
      end,
    }, "an array containing a function")
  end
)
