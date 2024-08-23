require("async.test")

local Helper = require("tests.promiseA+.helpers.init")

local dummy = { dummy = "dummy" } -- we fulfill or reject with this when we don't intend to test against it

describe("2.3.4: If `x` is not an object or function, fulfill `promise` with `x`", function()
  local function testValue(expectedValue, stringRepresentation)
    describe("The value is " .. stringRepresentation, function()
      Helper.test_fulfilled(async_it, dummy, function(promise1, done)
        local promise2 = promise1:thenCall(function()
          return expectedValue
        end)

        promise2:thenCall(function(actualValue)
          assert.are.equals(actualValue, expectedValue)
          done()
        end)
      end)

      Helper.test_rejected(async_it, dummy, function(promise1, done)
        local promise2 = promise1:thenCall(nil, function()
          return expectedValue
        end)

        promise2:thenCall(function(actualValue)
          assert.are.equals(actualValue, expectedValue)
          done()
        end)
      end)
    end)
  end

  testValue(false, "`false`")
  testValue(true, "`true`")
  testValue(0, "`0`")
end)
