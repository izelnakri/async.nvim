local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.filter_limit", function()
  after_each(function()
    wait(5)
  end)

  it("works on list collection", function()
    Callback.filter_limit({ 3, 4, 2, 1 }, 2, function(value, callback, index)
      Timers.set_timeout(function()
        callback(nil, (value % 2) == 1)
      end, index * 15)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.same(result, { 3, 1 })
    end)
  end)

  it("doesnt mutate the original list collection", function()
    local list = { 3, 4, 2, 1 }
    Callback.filter_limit(list, 2, function(value, callback)
      callback(nil, (value % 2) == 1)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.same(result, { 3, 1 })
    end)

    wait(0, function()
      assert.are.same(list, { 3, 4, 2, 1 })
    end)
  end)

  it("can filter an object correctly", function()
    local me = { name = "Izel", points = 32, last_name = "Nakri", active = true }

    Callback.filter_limit(me, 2, function(value, callback, key)
      Timers.set_timeout(function()
        callback(nil, type(value) == "string")
      end, 50)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.same(result, { name = "Izel", last_name = "Nakri" })
    end)
  end)

  it("can error", function()
    Callback.filter_limit({ 3, 1, 2 }, 2, function(element, callback)
      if element == 1 then
        return callback("error")
      end

      return callback(nil)
    end, function(err, result)
      assert.are.equal(err, "error")
      assert.are.equal(result, nil)
    end)
  end)

  it("can be cancelled", function()
    local call_order = {}

    Callback.filter_limit({ 3, 1, 2, 4, 5 }, 2, function(element, callback)
      table.insert(call_order, element)

      Timers.set_timeout(function()
        if element == 2 then
          return callback(false)
        end

        return callback(nil)
      end, 25)
    end, function()
      assert.True(false, "should not get here")
    end)

    wait(150, function()
      assert.are.equal(err, nil)
      assert.are.same(call_order, { 3, 1, 2, 4 })
      assert.are.equal(result, nil)
    end)
  end)
end)
