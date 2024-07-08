local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.try_each", function()
  after_each(function()
    wait(5)
  end)

  it("no callback doesnt throw", function()
    Callback.try_each({})
  end)

  it("calls result when its an empty list of tasks", function()
    Callback.try_each({}, function(err, results)
      assert.are.equal(err, nil)
      assert.are.equal(results, nil)
    end)
  end)

  it("can handle one task with multiple results", function()
    local RESULTS = { "something", "something2" }
    Callback.try_each({
      function(callback)
        callback(nil, RESULTS[1], RESULTS[2])
      end,
    }, function(err, results)
      assert.are.equal(err, nil)
      assert.are.same(results, RESULTS)
    end)
  end)

  it("it can handle one task successfully", function()
    local RESULT = "something"
    Callback.try_each({
      function(callback)
        callback(nil, RESULT)
      end,
    }, function(err, results)
      assert.are.equal(err, nil)
      assert.are.same(results, RESULT)
    end)
  end)

  it("can handle two tasks, one failing", function()
    local RESULT = "something"
    Callback.try_each({
      function(callback)
        callback("Failure message", {})
      end,
      function(callback)
        callback(nil, RESULT)
      end,
    }, function(err, results)
      assert.are.equal(err, nil)
      assert.are.equal(results, RESULT)
    end)
  end)

  it("can handle two tasks, both failing", function()
    Callback.try_each({
      function(callback)
        callback("Should not stop here")
      end,
      function(callback)
        callback("Failure2")
      end,
    }, function(err, results)
      assert.are.equal(err, "Failure2")
      assert.are.equal(results, nil)
    end)
  end)

  it("can handle two tasks, none failing", function()
    local RESULT = "something"

    Callback.try_each({
      function(callback)
        callback(nil, RESULT)
      end,
      function(callback)
        assert.True(false, "should not been called")
      end,
    }, function(err, results)
      assert.are.equal(err, nil)
      assert.are.equal(results, RESULT)
    end)
  end)

  it("can be canceled", function()
    local call_order = {}

    Callback.try_each({
      function(callback)
        table.insert(call_order, "task1")
        callback(false)
      end,
      function(callback)
        assert.True(false, "task2 should not been called")
      end,
    }, function(err, results)
      assert.True(false, "Results should not be called")
    end)

    wait(0, function()
      assert.are.same(call_order, { "task1" })
    end)
  end)
end)
