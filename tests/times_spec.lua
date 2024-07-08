local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.times", function()
  after_each(function()
    wait(5)
  end)

  it("works normally", function()
    local call_arguments = {}
    Callback.times(5, function(n, next)
      table.insert(call_arguments, n)
      next(nil, n * 10)
    end, function(err, results)
      assert.are.equal(err, nil)
      assert.are.same(call_arguments, { 1, 2, 3, 4, 5 })
      assert.are.same(results, { 10, 20, 30, 40, 50 })
    end)
  end)

  it("works when it has timeout inside", function()
    local call_arguments = {}
    Callback.times(3, function(n, next)
      Timers.set_timeout(function()
        table.insert(call_arguments, n)
        next(nil, n * 10)
      end, 10)
    end, function(err, results)
      assert.are.equal(err, nil)
      assert.are.same(call_arguments, { 1, 2, 3 })
      assert.are.same(results, { 10, 20, 30 })
    end)
  end)

  it("works when times is 0", function()
    local call_arguments = {}
    Callback.times(0, function(n, next)
      assert.True(false, "iteratee should not be called")
      next()
    end, function(err, results)
      assert.are.equal(err, nil)
      assert.are.same(call_arguments, {})
    end)
  end)

  it("can be errored", function()
    Callback.times(3, function(n, callback)
      callback("error")
    end, function(err, result)
      assert.are.equal(err, "error")
      assert.are.same(result, {})
    end)
  end)

  it("can be cancelled", function()
    local call_arguments = {}
    Callback.times(5, function(n, next)
      table.insert(call_arguments, n)
      if n == 2 then
        return next(false, n * 10)
      end

      next(nil, n * 10)
    end, function(err, results)
      assert.True(false, "should not get here")
    end)

    wait(0, function()
      assert.are.same(call_arguments, { 1, 2 })
    end)
  end)

  it("should finish before Callback.times_series and Callback.times_limit", function()
    local task_duration = 100
    local finished_operations = {}

    local times_timer = Timers.track_time()
    Callback.times(5, function(value, next)
      Timers.set_timeout(function()
        next()
      end, task_duration)
    end, function()
      times_timer = times_timer.stop()
      table.insert(finished_operations, "times")
    end)

    wait(task_duration * 5)

    local times_limit_timer = Timers.track_time()
    Callback.times_limit(5, 3, function(value, next)
      Timers.set_timeout(function()
        next()
      end, task_duration)
    end, function()
      times_limit_timer = times_limit_timer.stop()
      table.insert(finished_operations, "times_limit")
    end)

    wait(task_duration * 3)

    local times_series_timer = Timers.track_time()
    Callback.times_series(5, function(value, next)
      Timers.set_timeout(function()
        next()
      end, task_duration)
    end, function()
      times_series_timer = times_series_timer.stop()
      table.insert(finished_operations, "times_series")
    end)

    wait(task_duration * 6)

    assert.are.same(finished_operations, { "times", "times_limit", "times_series" })
    assert.True(times_timer.duration < times_limit_timer.duration)
    assert.True(times_timer.duration < times_series_timer.duration)
    assert.True(times_limit_timer.duration < times_series_timer.duration)
  end)
end)
