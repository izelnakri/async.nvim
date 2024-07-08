local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.race", function()
  after_each(function()
    wait(5)
  end)

  it("should call each function in parallel and callback with first result", function()
    local finished = 0
    local tasks = {}
    local eachTest = function(i)
      local index = i
      return function(next)
        finished = finished + 1
        next(nil, index * 2)
      end
    end

    for i = 0, 10 do
      tasks[i] = eachTest(i)
    end

    local race_result_call = 0
    Callback.race(tasks, function(err, result)
      race_result_call = race_result_call + 1
      assert.are.equal(err, nil)
      assert.are.equal(result, 2)
      assert.are.equal(finished, 1)
    end)

    wait(0, function()
      assert.are.equal(race_result_call, 1)
      assert.are.equal(finished, 10)
    end)
  end)

  it("should callback with the first error", function()
    local tasks = {}
    function eachTest(i)
      local index = i
      return function(next)
        Timers.set_timeout(function()
          next("ERR" .. index, "izel")
        end, 50 - index * 2)
      end
    end
    for i = 0, 5 do
      tasks[i] = eachTest(i)
    end

    local race_result_call = 0
    Callback.race(tasks, function(err, result)
      race_result_call = race_result_call + 1
      assert.are.equal(err, "ERR5")
      assert.are.equal(result, "izel")
    end)

    wait(120, function()
      assert.are.equal(race_result_call, 1)
    end)
  end)

  it("should callback when task is empty", function()
    Callback.race({}, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, nil)
    end)
  end)
end)
