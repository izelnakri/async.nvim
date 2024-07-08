local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.any_limit", function()
  after_each(function()
    wait(5)
  end)

  it("works for result true", function()
    Callback.any_limit({ "c", "a", "b" }, 2, function(x, callback)
      Timers.set_timeout(function()
        callback(nil, x == "a")
      end)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, true)
    end)
  end)

  it("works for result false", function()
    Callback.any_limit({ "c", "a", "b" }, 2, function(x, callback)
      Timers.set_timeout(function()
        callback(nil, x == "f")
      end)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, false)
    end)
  end)

  it("can early return", function()
    local calls = 0

    Callback.any_limit({ "f", "e", "d", "c", "a", "b" }, 2, function(x, callback)
      calls = calls + 1
      callback(nil, x == "d")
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, true)
      assert.are.equal(calls, 3)
    end)
  end)

  it("short circuit", function()
    local call_order = {}

    Callback.any_limit({ "a", "b", "c", "d", "e", "f" }, 2, function(x, callback, index)
      Timers.set_timeout(function()
        table.insert(call_order, x)
        callback(nil, x == "c")
      end, index * 15)
    end, function(err, result)
      table.insert(call_order, "callback")
      assert.equal(err, nil)
      assert.equal(result, true)
    end)

    wait(320, function()
      assert.are.same(call_order, { "a", "b", "c", "callback", "d" })
    end)
  end)

  it("can error", function()
    Callback.any_limit({ "a", "b", "c", "d", "e" }, 2, function(_, callback)
      Timers.set_timeout(function()
        callback("error")
      end)
    end, function(err, result)
      assert.are.equal(err, "error")
      assert.are.equal(result, nil)
    end)
  end)

  it("can be canceled", function()
    local call_order = {}

    Callback.any_limit({ "a", "b", "c", "d", "e" }, 2, function(x, callback, index)
      Timers.set_timeout(function()
        table.insert(call_order, x)
        if x == "c" then
          return callback(false, true)
        end
        callback(nil, false)
      end, index * 15)
    end, function()
      assert.True(false, "should not get here")
    end)

    wait(320, function()
      assert.are.same(call_order, { "a", "b", "c", "d" })
    end)
  end)
end)
