local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")
local null = require("callback.types.null")

describe("Callback.parallel_limit", function()
  it("works", function()
    local call_order = {}
    Callback.parallel_limit(
      {
        function(callback)
          Timers.set_timeout(function()
            table.insert(call_order, 1)
            callback(nil, 1)
          end, 10)
        end,
        function(callback)
          Timers.set_timeout(function()
            table.insert(call_order, 2)
            callback(nil, 2)
          end, 180)
        end,
        function(callback)
          Timers.set_timeout(function()
            table.insert(call_order, 3)
            callback(nil, 3, 3)
          end, 10)
        end,
      },
      2,
      function(err, results)
        assert.are.equal(err, nil)
        assert.are.same(call_order, { 1, 3, 2 })
        assert.are.same(results, { 1, 2, { 3, 3 } })
      end
    )

    wait(50)
  end)

  it("works on empty array", function()
    Callback.parallel_limit({}, 2, function(err, results)
      assert.are.equal(err, nil)
      assert.are.same(results, {})
    end)

    wait(50)
  end)

  it("error works correctly", function()
    Callback.parallel_limit(
      {
        function(callback)
          callback("error", 1)
        end,
        function(callback)
          callback("error2", 2)
        end,
      },
      1,
      function(err)
        assert.are.equal(err, "error")
      end
    )
    wait(100)
  end)

  it("works with no callback", function()
    Callback.parallel_limit({
      function(callback)
        callback()
      end,
      function(callback)
        callback()
      end,
    }, 1)
    wait(50)
  end)

  it("works on an object", function()
    local call_order = {}
    Callback.parallel_limit(
      {
        one = function(callback)
          Timers.set_timeout(function()
            table.insert(call_order, 1)
            callback(nil, 1)
          end, 125)
        end,
        two = function(callback)
          Timers.set_timeout(function()
            table.insert(call_order, null)
            callback(nil, 2)
          end, 350)
        end,
        three = function(callback)
          Timers.set_timeout(function()
            table.insert(call_order, 3)
            callback(nil, 3, 3)
          end, 50)
        end,
      },
      2,
      function(err, results)
        assert.are.equal(err, nil)
        assert.are.same(call_order, { 1, 3, 2 })
        assert.are.same(results, {
          one = 1,
          two = 2,
          three = { 3, 2 },
        })
      end
    )

    wait(50)
  end)

  it("can be cancelled", function()
    local call_order = {}
    Callback.parallel_limit(
      {
        function(callback)
          table.insert(call_order, 1)
          callback()
        end,
        function(callback)
          table.insert(call_order, 2)
          callback(false)
        end,
        function(callback)
          table.insert(call_order, 3)
          callback("error", 2)
        end,
      },
      1,
      function()
        assert.True(false, "should not get here")
      end
    )

    wait(0, function()
      assert.are.same(call_order, { 1, 2 })
    end)
  end)

  -- TODO: This doesnt work: return callback(error("Test Error")), make it fixed
  it("does not continue replenishing after error", function()
    local started = 0
    local func_to_call = function(callback)
      started = started + 1
      if started == 3 then
        return callback("Test Error")
      end
      Timers.set_timeout(function()
        callback()
      end, 10)
    end
    Callback.parallel_limit({
      func_to_call,
      func_to_call,
      func_to_call,
      func_to_call,
      func_to_call,
      func_to_call,
      func_to_call,
      func_to_call,
      func_to_call,
    }, 3, function() end)

    wait(0, function()
      assert.are.equal(started, 3)
    end)
  end)
end)
