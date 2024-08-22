require("tests.async")

local Promise = require("callback.types.promise")
local Timers = require("callback.utils.timers")
local spy = require("luassert.spy")
local dummy = { dummy = "dummy" } -- we fulfill or reject with this when we don't intend to test against it
local sentinel = { sentinel = "sentinel" } -- a sentinel fulfillment value to test for with strict equality

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

describe("2.3.2: If `x` is a promise, adopt its state", function()
  describe("2.3.2.1: If `x` is pending, `promise` must remain pending until `x` is fulfilled or rejected.", function()
    local function xFactory()
      return Promise.new(function() end)
    end

    testPromiseResolution(async_it, xFactory, function(promise, done)
      local fulfillment = spy.new(function() end)
      local rejection = spy.new(function() end)

      promise:thenCall(fulfillment, rejection)

      Timers.set_timeout(function()
        assert.spy(fulfillment).was_not_called()
        assert.spy(rejection).was_not_called()

        done()
      end, 100)
    end)
  end)

  describe("2.3.2.2: If/when `x` is fulfilled, fulfill `promise` with the same value.", function()
    describe("`x` is already-fulfilled", function()
      local function xFactory()
        return Promise.resolve(sentinel)
      end

      testPromiseResolution(async_it, xFactory, function(promise, done)
        promise:thenCall(function(value)
          assert.are.equals(value, sentinel)
          done()
        end)
      end)
    end)

    describe("`x` is eventually-fulfilled", function()
      local function xFactory()
        local promise, resolve = Promise.withResolvers()

        Timers.set_timeout(function()
          resolve(sentinel)
        end, 50)

        return promise
      end

      testPromiseResolution(async_it, xFactory, function(promise, done)
        promise:thenCall(function(value)
          assert.are_equals(value, sentinel)
          done()
        end)
      end)
    end)
  end)

  describe("2.3.2.3: If/when `x` is rejected, reject `promise` with the same reason.", function()
    describe("`x` is already-rejected", function()
      local function xFactory()
        return Promise.reject(sentinel)
      end

      testPromiseResolution(async_it, xFactory, function(promise, done)
        promise:thenCall(nil, function(reason)
          assert.are_equals(reason, sentinel)
          done()
        end)
      end)
    end)

    describe("`x` is eventually-rejected", function()
      local function xFactory()
        local promise, _, reject = Promise.withResolvers()

        Timers.set_timeout(function()
          reject(sentinel)
        end, 50)

        return promise
      end

      testPromiseResolution(async_it, xFactory, function(promise, done)
        promise:thenCall(nil, function(reason)
          assert.are_equals(reason, sentinel)
          done()
        end)
      end)
    end)
  end)
end)
