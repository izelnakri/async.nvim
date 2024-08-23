require("async.test")

local Callback = require("callback")
local Timers = require("timers")
local wait = require("tests.utils.wait")

describe("Callback.times_series", function()
  async_it("works normally", function()
    local call_arguments = {}
    Callback.times_series(5, function(n, next)
      table.insert(call_arguments, n)
      next(nil, n * 10)
    end, function(err, results)
      assert.are.equal(err, nil)
      assert.are.same(call_arguments, { 1, 2, 3, 4, 5 })
      assert.are.same(results, { 10, 20, 30, 40, 50 })
      done()
    end)
  end)

  async_it("works when it has timeout inside", function()
    local call_arguments = {}
    Callback.times_series(3, function(n, next)
      Timers.set_timeout(function()
        table.insert(call_arguments, n)
        next(nil, n * 10)
      end, 10)
    end, function(err, results)
      assert.are.equal(err, nil)
      assert.are.same(call_arguments, { 1, 2, 3 })
      assert.are.same(results, { 10, 20, 30 })
      done()
    end)
  end)

  async_it("works when times is 0", function()
    local call_arguments = {}
    Callback.times_series(0, function(n, next)
      assert.True(false, "iteratee should not be called")
      next()
    end, function(err, results)
      assert.are.equal(err, nil)
      assert.are.same(call_arguments, {})
      done()
    end)
  end)

  -- NOTE: maybe not working properly?
  it("can be errored", function()
    Callback.times_series(5, function(n, callback)
      if n == 3 then
        callback("error", n * 10)
      end
    end, function(err, result)
      assert.are.equal(err, "error")
      assert.are.same(result, { 10, 20, 30 })
    end)
  end)

  it("can be cancelled", function()
    local call_arguments = {}
    Callback.times_series(5, function(n, next)
      table.insert(call_arguments, n)

      if n == 3 then
        return next(false, n * 10)
      end

      next(nil, n * 10)
    end, function(err, results)
      assert.True(false, "should not get here")
    end)

    wait(5, function()
      assert.are.same(call_arguments, { 1, 2, 3 })
    end)
  end)
end)
