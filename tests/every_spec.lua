local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.every", function()
  after_each(function()
    wait(5)
  end)

  it("true", function()
    Callback.every({ "a", "b", "c" }, function(x, callback)
      Timers.set_timeout(function()
        callback(nil, true)
      end)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, true)
    end)
  end)

  it("false", function()
    Callback.every({ 1, 2, 3 }, function(x, callback)
      Timers.set_timeout(function()
        callback(nil, x % 2)
      end)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, true)
    end)
  end)

  it("early return", function()
    local call_order = {}

    Callback.every({ "a", "b", "c" }, function(x, callback)
      table.insert(call_order, x)
      callback(nil, x == "a")
    end, function(err, result)
      table.insert(call_order, "callback")
      assert.equal(err, nil)
      assert.equal(result, false)
    end)

    wait(0, function()
      assert.are.same(call_order, { "a", "b", "callback" })
    end)
  end)

  it("short circuit", function()
    local call_order = {}

    Callback.every({ "a", "b", "c" }, function(x, callback, index)
      Timers.set_timeout(function()
        table.insert(call_order, x)
        callback(nil, x == "a")
      end, index * 15)
    end, function(err, result)
      table.insert(call_order, "callback")
      assert.equal(err, nil)
      assert.equal(result, false)
    end)

    wait(350, function()
      assert.are.same(call_order, { "a", "b", "callback", "c" })
    end)
  end)

  it("error", function()
    Callback.every({ 1, 2, 3 }, function(_, callback)
      Timers.set_timeout(function()
        callback("error")
      end)
    end, function(err, result)
      assert.are.equal(err, "error")
      assert.are.equal(result, nil)
    end)
  end)

  it("canceled", function()
    local call_order = {}
    Callback.every({ "a", "b", "c" }, function(x, callback)
      table.insert(call_order, x)

      if x == "b" then
        return callback(false, true)
      end

      callback(nil, true)
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

    local each_timer = Timers.track_time()
    Callback.every(list, function(value, callback)
      table.insert(result, value)
      Timers.set_timeout(function()
        callback(nil, true)
      end, task_duration)
    end, function()
      each_timer = each_timer.stop()
      table.insert(finished_operations, "each")
    end)

    wait(task_duration * #list)

    local each_limit_timer = Timers.track_time()
    Callback.every_limit(list, 3, function(value, callback)
      table.insert(result, value)
      Timers.set_timeout(function()
        callback(nil, true)
      end, task_duration)
    end, function()
      each_limit_timer = each_limit_timer.stop()
      table.insert(finished_operations, "each_limit")
    end)

    wait(task_duration * 3)

    local each_series_timer = Timers.track_time()
    Callback.every_series(list, function(value, callback)
      table.insert(result, value)
      Timers.set_timeout(function()
        callback(nil, true)
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
