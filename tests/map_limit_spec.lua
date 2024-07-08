local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.map_series", function()
  after_each(function()
    wait(5)
  end)

  it("works on list collection", function()
    Callback.map_limit({ 3, 4, 2, 1 }, 2, function(value, callback, index)
      Timers.set_timeout(function()
        callback(nil, value * 2)
      end, index * 15)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.same(result, { 6, 8, 4, 2 })
    end)
  end)

  it("doesnt mutate the original list collection", function()
    local list = { 3, 4, 2, 1 }
    Callback.map_limit(list, 2, function(value, callback)
      callback(nil, value * 2)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.same(result, { 6, 8, 4, 2 })
    end)

    wait(0, function()
      assert.are.same(list, { 3, 4, 2, 1 })
    end)
  end)

  it("can error", function()
    Callback.map_limit({ 3, 1, 2, 9, 5, 7 }, 2, function(element, callback)
      if element == 9 then
        return callback("error", element * 2)
      end

      return callback(nil, element * 2)
    end, function(err, result)
      assert.are.equal(err, "error")
      assert.are.same(result, { 6, 2, 4, 18 })
    end)
  end)

  it("can be cancelled", function()
    local call_order = {}

    Callback.map_limit({ 3, 1, 2, 4, 5 }, 2, function(element, callback)
      table.insert(call_order, element)

      Timers.set_timeout(function()
        if element == 2 then
          return callback(false)
        end

        return callback(nil, element * 2)
      end, 25)
    end, function()
      assert.True(false, "should not get here")
    end)

    wait(100, function()
      assert.are.same(call_order, { 3, 1, 2, 4 })
    end)
  end)
end)
