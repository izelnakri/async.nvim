require("async.test")

local Callback = require("callback")
local Timers = require("timers")
local wait = require("tests.utils.wait")

describe("Callback.any", function()
  async_it("works", function()
    Callback.any({ "a", "b", "c" }, function(value, callback)
      Timers.set_timeout(function()
        callback(nil, value == "b")
      end)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, true)
      done()
    end)
  end)

  async_it("false case works correctly", function()
    Callback.any({ "a", "b", "c" }, function(x, callback)
      Timers.set_timeout(function()
        callback(nil, x == "x")
      end)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, false)
      done()
    end)
  end)

  it("early return", function()
    local call_order = {}

    Callback.any({ "a", "b", "c" }, function(x, callback)
      table.insert(call_order, x)
      callback(nil, x == "b")
    end, function(err, result)
      table.insert(call_order, "callback")
      assert.equal(err, nil)
      assert.equal(result, true)
    end)

    wait(0, function()
      assert.are.same(call_order, { "a", "b", "callback" })
    end)
  end)

  it("short circuit", function()
    local call_order = {}

    Callback.any({ "a", "b", "c" }, function(x, callback, index)
      Timers.set_timeout(function()
        table.insert(call_order, x)
        callback(nil, x == "b")
      end, index * 15)
    end, function(err, result)
      table.insert(call_order, "callback")
      assert.equal(err, nil)
      assert.equal(result, true)
    end)

    wait(90, function()
      assert.are.same(call_order, { "a", "b", "callback", "c" })
    end)
  end)

  async_it("error", function()
    Callback.any({ "a", "b", "c" }, function(_, callback)
      Timers.set_timeout(function()
        callback("error")
      end)
    end, function(err, result)
      assert.are.equal(err, "error")
      assert.are.equal(result, nil)
      done()
    end)
  end)

  it("canceled", function()
    local call_order = {}
    Callback.any({ "a", "b", "c" }, function(x, callback)
      table.insert(call_order, x)

      if x == "b" then
        return callback(false, true)
      end

      callback(nil, false)
    end, function()
      assert.True(false, "should not get here")
    end)

    wait(0, function()
      assert.are.same(call_order, { "a", "b" })
    end)
  end)

  it("should finish before Callback.every_series and Callback.every_limit", function()
    local task_duration = 100
    local list = { "a", "b", "c", "d", "e" }
    local result = {}
    local finished_operations = {}

    local any_timer = Timers.track_time()
    Callback.any(list, function(value, callback)
      table.insert(result, value)
      Timers.set_timeout(function()
        if value == "d" then
          return callback(nil, true)
        end

        callback(nil, false)
      end, task_duration)
    end, function()
      any_timer = any_timer.stop()
      table.insert(finished_operations, "any")
    end)

    wait(task_duration * #list)

    local any_limit_timer = Timers.track_time()
    Callback.any_limit(list, 3, function(value, callback)
      table.insert(result, value)
      Timers.set_timeout(function()
        if value == "d" then
          return callback(nil, true)
        end

        callback(nil, false)
      end, task_duration)
    end, function()
      any_limit_timer = any_limit_timer.stop()
      table.insert(finished_operations, "any_limit")
    end)

    wait(task_duration * 3)

    local any_series_timer = Timers.track_time()
    Callback.any_series(list, function(value, callback)
      table.insert(result, value)
      Timers.set_timeout(function()
        if value == "d" then
          return callback(nil, true)
        end

        callback(nil, false)
      end, task_duration)
    end, function()
      any_series_timer = any_series_timer.stop()
      table.insert(finished_operations, "any_series")
    end)

    wait(task_duration * (#list + 1))

    assert.are.same(finished_operations, { "any", "any_limit", "any_series" })
    assert.True(any_timer.duration < any_limit_timer.duration)
    assert.True(any_timer.duration < any_series_timer.duration)
    assert.True(any_limit_timer.duration < any_series_timer.duration)
  end)
end)
