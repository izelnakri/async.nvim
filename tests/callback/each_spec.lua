require("async.test")

local Timers = require("timers")
local Callback = require("callback")
local deep_equal = require("tests.utils.deep_equal")
local wait = require("tests.utils.wait")

describe("Callback.each", function()
  after_each(function()
    wait(5)
  end)

  async_it("it works with object", function()
    local args = {}
    Callback.each({ a = 1, b = 2 }, function(value, callback, key)
      Timers.set_timeout(function()
        table.insert(args, key)
        table.insert(args, value)
        callback(nil, key)
      end, value * 25)
    end, function(err, result)
      vim.print("cool")
      assert.are.equal(err, nil)
      assert.are.equal(result, "b")
      deep_equal(args, { "a", 1, "b", 2 })
      done()
    end)
  end)

  async_it("works with array", function()
    local args = {}
    Callback.each({ "a", "b" }, function(value, cb, index)
      table.insert(args, index)
      table.insert(args, value)
      cb(nil, index)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 2)
      assert.are.same(args, { 1, "a", 2, "b" })
      done()
    end)
  end)

  async_it("instant resolver", function()
    local args = {}
    Callback.each({ a = 1, b = 2 }, function(value, cb, key)
      table.insert(args, key)
      table.insert(args, value)
      cb(nil, key)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, "b")
      deep_equal(args, { "a", 1, "b", 2 })
      done()
    end)
  end)

  async_it("empty object", function()
    Callback.each({}, function(_, callback)
      assert.True(false, "iteratee should not be called")
      callback()
    end, function(err)
      assert.True(true, "should call callback")
      done()
    end)
  end)

  async_it("callback error value", function()
    local obj = { "a", "b", "c", "d", "e" }
    local call_order = {}

    Callback.each(obj, function(value, callback)
      table.insert(call_order, value)
      if value == "b" then
        return callback("error")
      end

      callback()
    end, function(err)
      assert.are.same(call_order, { "a", "b" })
      assert.are.equal(err, "error")
      done()
    end)
  end)

  it("with no callback provided", function()
    Callback.each({ a = 1 }, function(value, callback, key)
      assert.are.equal(key, "a")
      assert.are.equal(value, 1)
      callback()
    end)
  end)

  it("can be canceled (async, array)", function()
    local arr = { "a", "b", "c", "d", "e" }
    local call_order = {}

    Callback.each(arr, function(value, callback, index)
      table.insert(call_order, index)
      table.insert(call_order, value)
      Timers.set_timeout(function()
        if value == "b" then
          return callback(false)
        end
        callback()
      end)
    end, function()
      assert.True(false, "should not get here")
    end)

    wait(0, function()
      assert.are.same(call_order, { 1, "a", 2, "b", 3, "c", 4, "d", 5, "e" })
    end)
  end)

  it("should finish before Callback.each_series and Callback.each_limit", function()
    local task_duration = 100
    local list = { "a", "b", "c", "d", "e" }
    local result = {}
    local finished_operations = {}

    local each_timer = Timers.track_time()
    Callback.each(list, function(value, callback, index)
      table.insert(result, index)
      table.insert(result, value)
      Timers.set_timeout(function()
        callback()
      end, task_duration)
    end, function()
      each_timer = each_timer.stop()
      table.insert(finished_operations, "each")
    end)

    wait(task_duration * #list)

    local each_limit_timer = Timers.track_time()
    Callback.each_limit(list, 3, function(value, callback, index)
      table.insert(result, index)
      table.insert(result, value)
      Timers.set_timeout(function()
        callback()
      end, task_duration)
    end, function()
      each_limit_timer = each_limit_timer.stop()
      table.insert(finished_operations, "each_limit")
    end)

    wait(task_duration * 3)

    local each_series_timer = Timers.track_time()
    Callback.each_series(list, function(value, callback, index)
      table.insert(result, index)
      table.insert(result, value)
      Timers.set_timeout(function()
        callback()
      end, task_duration)
    end, function()
      each_series_timer = each_series_timer.stop()
      table.insert(finished_operations, "each_series")
    end)

    wait(task_duration * (#list + 1))

    assert.are.same(finished_operations, { "each", "each_limit", "each_series" })
    assert.True(each_timer.duration < each_limit_timer.duration)
    assert.True(each_timer.duration < each_series_timer.duration)
    assert.True(each_limit_timer.duration < each_series_timer.duration)
  end)
end)
