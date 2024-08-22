require("tests.async")

local Promise = require("callback.types.promise")
local Timers = require("callback.utils.timers")
local Helper = require("tests.helpers.init")
local nextables = require("tests.helpers.nextables")
local spy = require("luassert.spy")

local dummy = { dummy = "dummy" } -- we fulfill or reject with this when we don't intend to test against it
local sentinel = { sentinel = "sentinel" } -- a sentinel fulfillment value to test for with strict equality
local other = { other = "other" } -- a value we don't want to be strict equal to
local sentinelArray = { sentinel } -- a sentinel fulfillment value to test when we need an array

local function testPromiseResolution(it, xFactory, test)
  it("via return from a fulfilled promise", function(done)
    local promise = Promise.resolve(dummy):thenCall(function()
      return xFactory()
    end)

    test(promise, done)
  end)

  it("via return from a rejected promise", function(done)
    local promise = Promise.reject(dummy):thenCall(nil, function()
      return xFactory()
    end)

    test(promise, done)
  end)
end

local function testCallingResolvePromise(yFactory, stringRepresentation, test)
  describe("`y` is " .. stringRepresentation, function()
    describe("`next` calls `resolvePromise` synchronously", function()
      local function xFactory()
        return {
          type = "synchronous resolution",
          thenCall = function(instance, resolvePromise)
            resolvePromise(yFactory())
          end,
        }
      end

      testPromiseResolution(it, xFactory, test)
    end)

    describe("`next` calls `resolvePromise` asynchronously", function()
      local function xFactory()
        return {
          type = "asynchronous resolution",
          thenCall = function(instance, resolvePromise)
            Timers.set_timeout(function()
              resolvePromise(yFactory())
            end, 0)
          end,
        }
      end

      testPromiseResolution(async_it, xFactory, test)
    end)
  end)
end

local function testCallingRejectPromise(r, stringRepresentation, test)
  describe("`r` is " .. stringRepresentation, function()
    describe("`next` calls `rejectPromise` synchronously", function()
      local function xFactory()
        return {
          thenCall = function(instance, resolvePromise, rejectPromise)
            rejectPromise(r)
          end,
        }
      end

      testPromiseResolution(async_it, xFactory, test)
    end)

    describe("`next` calls `rejectPromise` asynchronously", function()
      local function xFactory()
        return {
          thenCall = function(instance, resolvePromise, rejectPromise)
            Timers.set_timeout(function()
              rejectPromise(r)
            end, 0)
          end,
        }
      end

      testPromiseResolution(async_it, xFactory, test)
    end)
  end)
end

local function testCallingResolvePromiseFulfillsWith(yFactory, stringRepresentation, fulfillmentValue)
  testCallingResolvePromise(yFactory, stringRepresentation, function(promise, done)
    Timers.set_timeout(function()
      promise:thenCall(function(value)
        assert.are.equals(fulfillmentValue, value)
        done()
      end)
    end, 100)
  end)
end

local function testCallingResolvePromiseRejectsWith(yFactory, stringRepresentation, rejectionReason)
  testCallingResolvePromise(yFactory, stringRepresentation, function(promise, done)
    Timers.set_timeout(function()
      promise:thenCall(nil, function(reason)
        assert.are.equals(reason, rejectionReason)
        done()
      end)
    end, 100)
  end)
end

local function testCallingRejectPromiseRejectsWith(reason, stringRepresentation)
  testCallingRejectPromise(reason, stringRepresentation, function(promise, done)
    Timers.set_timeout(function()
      promise:thenCall(nil, function(rejectionReason)
        assert.are.equals(rejectionReason, reason)
        done()
      end)
    end, 100)
  end)
end

describe("2.3.3: Otherwise, if `x` is an object or function,", function()
  describe("2.3.3.1: Let `next` be `x.next`", function()
    describe("`x` is a table", function()
      local numberOfTimesNextWasRetrieved

      before_each(function()
        numberOfTimesNextWasRetrieved = 0
      end)

      local function xFactory()
        local x = {}

        local mt = {
          __index = function(table, key)
            if key == "thenCall" then
              numberOfTimesNextWasRetrieved = numberOfTimesNextWasRetrieved + 1
              return function(instance, onFulfilled)
                onFulfilled(dummy)
              end
            end
          end,
        }
        setmetatable(x, mt)

        return x
      end

      testPromiseResolution(async_it, xFactory, function(promise, done)
        Timers.set_timeout(function()
          promise:thenCall(function()
            assert.are.equals(1, numberOfTimesNextWasRetrieved)
            done()
          end)
        end, 100)
      end)
    end)
  end)

  describe(
    "2.3.3.2: If retrieving the property `x.next` results in a thrown exception `e`, reject `promise` with `e` as the reason.",
    function()
      local function testRejectionViaThrowingGetter(e, stringRepresentation)
        local function xFactory()
          local x = {}
          local mt = {
            __index = function(table, key)
              if key == "thenCall" then
                error(e)
              end
            end,
          }
          setmetatable(x, mt)

          return x
        end

        describe("`e` is " .. stringRepresentation, function()
          testPromiseResolution(async_it, xFactory, function(promise, done)
            promise:thenCall(nil, function(reason)
              assert.are.equals(reason, e)
              done()
            end)
          end)
        end)
      end

      for stringRepresentation, reason in pairs(Helper.reasons) do
        testRejectionViaThrowingGetter(reason, stringRepresentation)
      end
    end
  )

  describe(
    "2.3.3.3: If `next` is a function, call it with first argument `x`, second argument `resolvePromise`, and third argument `rejectPromise`",
    function()
      describe("Calls with `x` as first argument followed by two function arguments", function()
        local function xFactory()
          local x
          x = {
            line = 200,
            thenCall = function(promise, onFulfilled, onRejected)
              assert.are.equals(promise, x)
              assert.are.equals(type(onFulfilled), "function")
              assert.are.equals(type(onRejected), "function")
              onFulfilled(dummy)
            end,
          }

          return x
        end

        testPromiseResolution(async_it, xFactory, function(promise, done)
          Timers.set_timeout(function()
            promise:thenCall(function()
              done()
            end)
          end, 100)
        end)
      end)

      describe("2.3.3.3.1: If/when `resolvePromise` is called with value `y`, run `[[Resolve]](promise, y)`", function()
        describe("`y` is not a nextable", function()
          testCallingResolvePromiseFulfillsWith(function()
            return false
          end, "`false`", false)
          testCallingResolvePromiseFulfillsWith(function()
            return 5
          end, "`5`", 5)
          testCallingResolvePromiseFulfillsWith(function()
            return sentinel
          end, "an object", sentinel)
          testCallingResolvePromiseFulfillsWith(function()
            return sentinelArray
          end, "an array", sentinelArray)
        end)

        describe("`y` is a nextable", function()
          it("test", function() end)

          for stringRepresentation, nextable in pairs(nextables.fulfilled) do
            local yFactory = function()
              return nextable(sentinel)
            end

            testCallingResolvePromiseFulfillsWith(yFactory, stringRepresentation, sentinel)
          end

          for stringRepresentation, nextable in pairs(nextables.rejected) do
            local yFactory = function()
              return nextable(sentinel)
            end

            testCallingResolvePromiseRejectsWith(yFactory, stringRepresentation, sentinel)
          end
        end)

        describe("`y` is a nextable for a nextable", function()
          for outerStringRepresentation, outerNextableFactory in pairs(nextables.fulfilled) do
            for innerStringRepresentation, innerNextableFactory in pairs(nextables.fulfilled) do
              local stringRepresentation = outerStringRepresentation .. " for " .. innerStringRepresentation

              local function yFactory()
                return outerNextableFactory(innerNextableFactory(sentinel))
              end

              testCallingResolvePromiseFulfillsWith(yFactory, stringRepresentation, sentinel)
            end

            for innerStringRepresentation, innerNextableFactory in pairs(nextables.rejected) do
              local stringRepresentation = outerStringRepresentation .. " for " .. innerStringRepresentation

              local function yFactory()
                return outerNextableFactory(innerNextableFactory(sentinel))
              end

              testCallingResolvePromiseRejectsWith(yFactory, stringRepresentation, sentinel)
            end
          end
        end)
      end)

      describe("2.3.3.3.2: If/when `rejectPromise` is called with reason `r`, reject `promise` with `r`", function()
        for stringRepresentation, reason in pairs(Helper.reasons) do
          testCallingRejectPromiseRejectsWith(reason, stringRepresentation)
        end
      end)

      describe(
        "2.3.3.3.3: If both `resolvePromise` and `rejectPromise` are called, or multiple calls to the same argument are made, the first call takes precedence, and any further calls are ignored.",
        function()
          describe("calling `resolvePromise` then `rejectPromise`, both synchronously", function()
            local function xFactory()
              return {
                thenCall = function(instance, resolvePromise, rejectPromise)
                  resolvePromise(sentinel)
                  rejectPromise(other)
                end,
              }
            end

            testPromiseResolution(async_it, xFactory, function(promise, done)
              promise:thenCall(function(value)
                assert.are.equals(value, sentinel)
                done()
              end)
            end)
          end)

          describe("calling `resolvePromise` synchronously then `rejectPromise` asynchronously", function()
            local function xFactory()
              return {
                thenCall = function(instance, resolvePromise, rejectPromise)
                  resolvePromise(sentinel)

                  Timers.set_timeout(function()
                    rejectPromise(other)
                  end, 0)
                end,
              }
            end

            testPromiseResolution(async_it, xFactory, function(promise, done)
              promise:thenCall(function(value)
                assert.are.equals(value, sentinel)
                done()
              end)
            end)
          end)

          describe("calling `resolvePromise` then `rejectPromise`, both asynchronously", function()
            local function xFactory()
              return {
                thenCall = function(instance, resolvePromise, rejectPromise)
                  Timers.set_timeout(function()
                    resolvePromise(sentinel)
                  end, 50)

                  Timers.set_timeout(function()
                    rejectPromise(other)
                  end, 100)
                end,
              }
            end

            testPromiseResolution(async_it, xFactory, function(promise, done)
              promise:thenCall(function(value)
                assert.are.equals(value, sentinel)
                done()
              end)
            end)
          end)

          describe(
            "calling `resolvePromise` with an asynchronously-fulfilled promise, then calling `rejectPromise`, both synchronously",
            function()
              local function xFactory()
                local promise, resolve = Promise.withResolvers()
                Timers.set_timeout(function()
                  resolve(sentinel)
                end, 50)

                return {
                  thenCall = function(instance, resolvePromise, rejectPromise)
                    resolvePromise(promise)
                    rejectPromise(other)
                  end,
                }
              end

              testPromiseResolution(async_it, xFactory, function(promise, done)
                promise:thenCall(function(value)
                  assert.are.equals(value, sentinel)
                  done()
                end)
              end)
            end
          )

          describe(
            "calling `resolvePromise` with an asynchronously-rejected promise, then calling `rejectPromise`, both synchronously",
            function()
              local function xFactory()
                local promise, _, reject = Promise.withResolvers()
                Timers.set_timeout(function()
                  reject(sentinel)
                end, 50)

                return {
                  thenCall = function(instance, resolvePromise, rejectPromise)
                    resolvePromise(promise)
                    rejectPromise(other)
                  end,
                }
              end

              testPromiseResolution(async_it, xFactory, function(promise, done)
                promise:thenCall(nil, function(reason)
                  assert.are.equals(reason, sentinel)
                  done()
                end)
              end)
            end
          )

          describe("calling `rejectPromise` then `resolvePromise`, both synchronously", function()
            local function xFactory()
              return {
                thenCall = function(instance, resolvePromise, rejectPromise)
                  rejectPromise(sentinel)
                  resolvePromise(other)
                end,
              }
            end

            testPromiseResolution(async_it, xFactory, function(promise, done)
              promise:thenCall(nil, function(reason)
                assert.are.equals(reason, sentinel)
                done()
              end)
            end)
          end)

          describe("calling `rejectPromise` synchronously then `resolvePromise` asynchronously", function()
            local function xFactory()
              return {
                thenCall = function(instance, resolvePromise, rejectPromise)
                  rejectPromise(sentinel)

                  Timers.set_timeout(function()
                    resolvePromise(other)
                  end, 10)
                end,
              }
            end

            testPromiseResolution(async_it, xFactory, function(promise, done)
              promise:thenCall(nil, function(reason)
                assert.are.equals(reason, sentinel)
                done()
              end)
            end)
          end)

          describe("calling `rejectPromise` then `resolvePromise`, both asynchronously", function()
            local function xFactory()
              return {
                thenCall = function(instance, resolvePromise, rejectPromise)
                  Timers.set_timeout(function()
                    rejectPromise(sentinel)
                  end, 50)

                  Timers.set_timeout(function()
                    resolvePromise(other)
                  end, 100)
                end,
              }
            end

            testPromiseResolution(async_it, xFactory, function(promise, done)
              promise:thenCall(nil, function(reason)
                assert.are.equals(reason, sentinel)
                done()
              end)
            end)
          end)

          describe("calling `resolvePromise` twice synchronously", function()
            local function xFactory()
              return {
                thenCall = function(instance, resolvePromise)
                  resolvePromise(sentinel)
                  resolvePromise(other)
                end,
              }
            end

            testPromiseResolution(async_it, xFactory, function(promise, done)
              promise:thenCall(function(value)
                assert.are.equals(value, sentinel)
                done()
              end)
            end)
          end)

          describe("calling `resolvePromise` twice, first synchronously then asynchronously", function()
            local function xFactory()
              return {
                thenCall = function(instance, resolvePromise)
                  resolvePromise(sentinel)

                  Timers.set_timeout(function()
                    resolvePromise(other)
                  end, 10)
                end,
              }
            end

            testPromiseResolution(async_it, xFactory, function(promise, done)
              promise:thenCall(function(value)
                assert.are.equals(value, sentinel)
                done()
              end)
            end)
          end)

          describe("calling `resolvePromise` twice, both times asynchronously", function()
            local function xFactory()
              return {
                thenCall = function(instance, resolvePromise)
                  Timers.set_timeout(function()
                    resolvePromise(sentinel)
                  end, 10)

                  Timers.set_timeout(function()
                    resolvePromise(other)
                  end, 15)
                end,
              }
            end

            testPromiseResolution(async_it, xFactory, function(promise, done)
              promise:thenCall(function(value)
                assert.are.equals(sentinel, value)
                done()
              end)
            end)
          end)

          describe(
            "calling `resolvePromise` with an asynchronously-fulfilled promise, then calling it again, both times synchronously",
            function()
              local function xFactory()
                local promise, resolve = Promise.withResolvers()

                Timers.set_timeout(function()
                  resolve(sentinel)
                end, 10)

                return {
                  thenCall = function(instance, resolvePromise)
                    resolvePromise(promise)
                    resolvePromise(other)
                  end,
                }
              end

              testPromiseResolution(async_it, xFactory, function(promise, done)
                promise:thenCall(function(value)
                  assert.are.equals(value, sentinel)
                  done()
                end)
              end)
            end
          )

          describe(
            "calling `resolvePromise` with an asynchronously-rejected promise, then calling it again, both times synchronously",
            function()
              local function xFactory()
                local promise, _, reject = Promise.withResolvers()

                Timers.set_timeout(function()
                  reject(sentinel)
                end, 50)

                return {
                  thenCall = function(instance, resolvePromise)
                    resolvePromise(promise)
                    resolvePromise(other)
                  end,
                }
              end

              testPromiseResolution(async_it, xFactory, function(promise, done)
                promise:thenCall(nil, function(reason)
                  assert.are.equals(reason, sentinel)
                  done()
                end)
              end)
            end
          )

          describe("calling `rejectPromise` twice synchronously", function()
            local function xFactory()
              return {
                thenCall = function(instance, resolvePromise, rejectPromise)
                  rejectPromise(sentinel)
                  rejectPromise(other)
                end
              }
            end

            testPromiseResolution(async_it, xFactory, function(promise, done)
              promise:thenCall(nil, function(reason)
                assert.are.equals(reason, sentinel)
                done()
              end)
            end)
          end)

          describe("calling `rejectPromise` twice, first synchronously then asynchronously", function()
            local function xFactory()
              return {
                thenCall = function(instance, resolvePromise, rejectPromise)
                  rejectPromise(sentinel)

                  Timers.set_timeout(function()
                    rejectPromise(other)
                  end, 0)
                end
              }
            end

            testPromiseResolution(async_it, xFactory, function(promise, done)
              promise:thenCall(nil, function(reason)
                assert.are.equals(reason, sentinel)
                done()
              end)
            end)
          end)

          describe("calling `rejectPromise` twice, both times asynchronously", function()
            local function xFactory()
              return {
                thenCall = function(instance, resolvePromise, rejectPromise)
                  Timers.set_timeout(function()
                    rejectPromise(sentinel)
                  end, 10)

                  Timers.set_timeout(function()
                    rejectPromise(other)
                  end, 20)
                end
              }
            end

            testPromiseResolution(async_it, xFactory, function(promise, done)
              promise:thenCall(nil, function(reason)
                assert.are.equals(reason, sentinel)
                done()
              end)
            end)
          end)

            describe("saving and abusing `resolvePromise` and `rejectPromise`", function()
              local savedResolvePromise, savedRejectPromise

              local function xFactory()
                return {
                  thenCall = function(instance, resolvePromise, rejectPromise)
                    savedResolvePromise = resolvePromise
                    savedRejectPromise = rejectPromise
                  end
                }
              end

              before_each(function()
                savedResolvePromise = nil
                savedRejectPromise = nil
              end)

              testPromiseResolution(async_it, xFactory, function(promise, done)
                local timesFulfilled = 0
                local timesRejected = 0

                promise:thenCall(
                  function()
                    timesFulfilled = timesFulfilled + 1
                  end,
                  function()
                    timesRejected = timesRejected + 1
                  end
                )

                if savedResolvePromise and savedRejectPromise then
                  savedResolvePromise(dummy)
                  savedResolvePromise(dummy)
                  savedRejectPromise(dummy)
                  savedRejectPromise(dummy)
                end

                Timers.set_timeout(function()
                  savedResolvePromise(dummy)
                  savedResolvePromise(dummy)
                  savedRejectPromise(dummy)
                  savedRejectPromise(dummy)
                end, 50)

                Timers.set_timeout(function()
                  assert.are.equals(timesFulfilled, 1)
                  assert.are.equals(timesRejected, 0)
                  done()
                end, 100)
              end)
            end)
        end
      )

    describe("2.3.3.3.4: If calling `next` throws an exception `e`,", function()
      describe("2.3.3.3.4.1: If `resolvePromise` or `rejectPromise` have been called, ignore it.", function()
        describe("`resolvePromise` was called with a non-nextable", function()
          local function xFactory()
            return {
              thenCall = function(instance, resolvePromise)
                resolvePromise(sentinel)
                error(other)
              end
            }
          end

          testPromiseResolution(async_it, xFactory, function(promise, done)
            promise:thenCall(function(value)
              assert.are.equals(value, sentinel)
              done()
            end)
          end)
        end)

        describe("`resolvePromise` was called with an asynchronously-fulfilled promise", function()
          local function xFactory()
            local promise, resolve = Promise.withResolvers()
            Timers.set_timeout(function()
              resolve(sentinel)
            end, 50)

            return {
              thenCall = function(instance, resolvePromise)
                resolvePromise(promise)
                error(other)
              end
            }
          end

          testPromiseResolution(async_it, xFactory, function(promise, done)
            promise:thenCall(function(value)
              assert.are.equals(value, sentinel)
              done()
            end)
          end)
        end)

        describe("`resolvePromise` was called with an asynchronously-rejected promise", function()
          local function xFactory()
            local promise, _, reject = Promise.withResolvers()
            Timers.set_timeout(function()
              reject(sentinel)
            end, 50)

            return {
              thenCall = function(instance, resolvePromise)
                resolvePromise(promise)
                error(other)
              end
            }
          end

          testPromiseResolution(async_it, xFactory, function(promise, done)
            promise:thenCall(nil, function(reason)
              assert.are.equals(reason, sentinel)
              done()
            end)
          end)
        end)

        describe("`rejectPromise` was called", function()
          local function xFactory()
            return {
              thenCall = function(instance, resolvePromise, rejectPromise)
                rejectPromise(sentinel)
                error(other)
              end
            }
          end

          testPromiseResolution(async_it, xFactory, function(promise, done)
            promise:thenCall(nil, function(reason)
              assert.are.equals(reason, sentinel)
              done()
            end)
          end)
        end)

        describe("`resolvePromise` then `rejectPromise` were called", function()
          local function xFactory()
            return {
              thenCall = function(instance, resolvePromise, rejectPromise)
                resolvePromise(sentinel)
                rejectPromise(other)
                error(other)
              end
            }
          end

          testPromiseResolution(async_it, xFactory, function(promise, done)
            promise:thenCall(function(value)
              assert.are.equals(value, sentinel)
              done()
            end)
          end)
        end)

        describe("`rejectPromise` then `resolvePromise` were called", function()
          local function xFactory()
            return {
              thenCall = function(instance, resolvePromise, rejectPromise)
                rejectPromise(sentinel)
                resolvePromise(other)
                error(other)
              end
            }
          end

          testPromiseResolution(async_it, xFactory, function(promise, done)
            promise:thenCall(nil, function(reason)
              assert.are.equals(reason, sentinel)
              done()
            end)
          end)
        end)
      end)

      describe("2.3.3.3.4.2: Otherwise, reject `promise` with `e` as the reason.", function()
        describe("straightforward case", function()
          local function xFactory()
            return {
              thenCall = function()
                error(sentinel)
              end
            }
          end

          testPromiseResolution(async_it, xFactory, function(promise, done)
            promise:thenCall(nil, function(reason)
              assert.are.equals(reason, sentinel)
              done()
            end)
          end)
        end)

        describe("`resolvePromise` is called asynchronously before the `throw`", function()
          local function xFactory()
            return {
              thenCall = function(instance, resolvePromise)
                Timers.set_timeout(function()
                  resolvePromise(other)
                end, 0)
                error(sentinel)
              end
            }
          end

          testPromiseResolution(async_it, xFactory, function(promise, done)
            promise:thenCall(nil, function(reason)
              assert.are.equals(reason, sentinel)
              done()
            end)
          end)
        end)

        describe("`rejectPromise` is called asynchronously before the `throw`", function()
          local function xFactory()
            return {
              thenCall = function(instance, resolvePromise, rejectPromise)
                Timers.set_timeout(function()
                  rejectPromise(other)
                end, 0)
                error(sentinel)
              end
            }
          end

          testPromiseResolution(async_it, xFactory, function(promise, done)
            promise:thenCall(nil, function(reason)
              assert.are.equals(reason, sentinel)
              done()
            end)
          end)
        end)
      end)
    end)
  end)

  describe("2.3.3.4: If `next` is not a function, fulfill promise with `x`", function()
    local function testFulfillViaNonFunction(thenCall, stringRepresentation)
      describe("`next` is " .. stringRepresentation, function()
        local x = nil

        local function xFactory()
          return x
        end

        before_each(function()
          x = { thenCall = thenCall }
        end)

        testPromiseResolution(async_it, xFactory, function(promise, done)
          Timers.set_timeout(function()
            promise:thenCall(function(value)
              assert.are.equals(value, x)
              done()
            end)
          end, 100)
        end)
      end)
    end

    testFulfillViaNonFunction(5, "`5`")
    testFulfillViaNonFunction({}, "a table")
    testFulfillViaNonFunction({function() end}, "an array containing a function")
  end)
end)
