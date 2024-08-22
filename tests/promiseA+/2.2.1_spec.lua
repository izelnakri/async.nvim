require("tests.async")

local dummy = { dummy = "dummy" }
local Promise = require("callback.types.promise")

describe("2.2.1: Both `onFulfilled` and `onRejected` are optional arguments.", function()
  describe("2.2.1.1: If `onFulfilled` is not a function, it must be ignored.", function()
    describe("applied to a directly-rejected promise", function()
      local function testNonFunction(non_function, string_representation)
        async_it("`onFulfilled` is " .. string_representation, function(done)
          Promise.reject(dummy):thenCall(non_function, function()
            done()
          end)
        end)
      end

      testNonFunction(nil, "`nil`")
      testNonFunction(false, "`false`")
      testNonFunction(5, "`5`")
      testNonFunction({}, "a table")
    end)

    describe("applied to a promise rejected and then chained off of", function()
      local function testNonFunction(nonFunction, stringRepresentation)
        async_it("`onFulfilled` is " .. stringRepresentation, function(done)
          Promise.reject(dummy):thenCall(function() end, nil):thenCall(nonFunction, function()
            done()
          end)
        end)
      end

      testNonFunction(nil, "`nil`")
      testNonFunction(false, "`false`")
      testNonFunction(5, "`5`")
      testNonFunction({}, "a table")
    end)
  end)

  describe("2.2.1.2: If `onRejected` is not a function, it must be ignored.", function()
    describe("applied to a directly-fulfilled promise", function()
      local function testNonFunction(nonFunction, stringRepresentation)
        async_it("`onRejected` is " .. stringRepresentation, function(done)
          Promise.resolve(dummy):thenCall(function()
            done()
          end, nonFunction)
        end)
      end

      testNonFunction(nil, "`null`")
      testNonFunction(false, "`false`")
      testNonFunction(5, "`5`")
      testNonFunction({}, "a table")
    end)

    describe("applied to a promise fulfilled and then chained off of", function()
      local function testNonFunction(nonFunction, stringRepresentation)
        async_it("`onFulfilled` is " .. stringRepresentation, function(done)
          Promise.resolve(dummy):thenCall(nil, function() end):thenCall(function()
            done()
          end, nonFunction)
        end)
      end

      testNonFunction(nil, "`null`")
      testNonFunction(false, "`false`")
      testNonFunction(5, "`5`")
      testNonFunction({}, "an object")
    end)
  end)
end)
