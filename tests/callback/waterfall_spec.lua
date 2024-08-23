require("async.test")

local Callback = require("callback")
local Timers = require("timers")
local wait = require("tests.utils.wait")
local null = require("callback.types.null")

describe("Callback.waterfall", function()
  after_each(function()
    wait(5)
  end)

  async_it("basics", function()
    local call_order = {}
    Callback.waterfall({
      function(callback)
        table.insert(call_order, "fn1")
        Timers.set_timeout(function()
          callback(nil, "one", "two")
        end)
      end,
      function(arg1, arg2, callback)
        table.insert(call_order, "fn2")
        assert.are.equal(arg1, "one")
        assert.are.equal(arg2, "two")
        Timers.set_timeout(function()
          callback(nil, arg1, arg2, "three")
        end, 25)
      end,
      function(arg1, arg2, arg3, callback)
        table.insert(call_order, "fn3")
        assert.are.equal(arg1, "one")
        assert.are.equal(arg2, "two")
        assert.are.equal(arg3, "three")
        callback(nil, "four")
      end,
      function(arg4, callback)
        table.insert(call_order, "fn4")
        assert.are.same(call_order, { "fn1", "fn2", "fn3", "fn4" })
        callback(nil, "test")
      end,
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, "test")
      done()
    end)
  end)

  async_it("empty array", function()
    Callback.waterfall({}, function(err)
      if err then
        assert.True(false, "should not have error")
      end
      done()
    end)
  end)

  it("works with no callback", function()
    Callback.waterfall({
      function(callback)
        callback()
      end,
      function(callback)
        callback()
      end,
    })
  end)

  async_it("works with right order of execution inside the waterfall", function()
    local call_order = {}
    Callback.waterfall({
      function(callback)
        table.insert(call_order, 1)
        callback()
        table.insert(call_order, 2)
      end,
      function(callback)
        table.insert(call_order, 3)
        callback()
      end,
      function()
        assert.are.same(call_order, { 1, 3 })
        done()
      end,
    })
  end)

  async_it("works for error handler", function()
    Callback.waterfall({
      function(callback)
        callback("error")
      end,
      function()
        assert.True(false, "next function should not be called")
      end,
    }, function(err)
      assert.are.equal(err, "error")
      done()
    end)
  end)

  it("can be cancelled", function()
    local call_order = {}
    Callback.waterfall({
      function(callback)
        table.insert(call_order, 1)
        callback(false)
      end,
      function(callback)
        table.insert(call_order, 2)
        assert.True(false, "next function should not be called")
      end,
    }, function()
      assert.True(false, "should not get here")
    end)

    wait(0, function()
      assert.are.same(call_order, { 1 })
    end)
  end)

  it("multiple callback calls fails the waterfall correctly", function()
    local arr = {
      function(callback)
        callback(nil, "one", "two")
        callback(nil, "one", "two")
      end,
      function(arg1, arg2, callback)
        callback(nil, arg1, arg2, "three")
      end,
    }

    assert.has_error(function()
      Callback.waterfall(arr, function() end)
    end)
  end)
end)
