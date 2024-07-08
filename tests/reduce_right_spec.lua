local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.reduce_right", function()
  it("works synchronously", function()
    local call_order = {}
    local operation_result
    Callback.reduce_right(
      { 2, 4, 5 },
      function(result, value, callback, index)
        table.insert(call_order, index)
        table.insert(call_order, value)

        callback(nil, result + value) -- callback(nil, result + value)
      end,
      0,
      function(err, result)
        operation_result = result
        assert.are.equal(err, nil)
        assert.are.equal(result, 11)
      end
    )

    wait(50, function()
      assert.are.same(call_order, { 3, 5, 2, 4, 1, 2 })
      assert.are.equal(operation_result, 11)
    end)
  end)

  it("result gets built correctly inside callbacks that have callbacks", function()
    local call_order = {}
    local operation_result
    Callback.reduce_right(
      { 2, 4, 5 },
      function(result, value, callback, index)
        table.insert(call_order, index)
        table.insert(call_order, value)
        Timers.set_timeout(function()
          callback(nil, result + value)
        end, 25 * value)
      end,
      0,
      function(err, result)
        operation_result = result
        assert.are.equal(err, nil)
        assert.are.equal(result, 11)
      end
    )

    wait(800, function()
      assert.are.same(call_order, { 3, 5, 2, 4, 1, 2 })
      assert.are.equal(operation_result, 11)
    end)
  end)

  it("works when collection is an object instead of a list", function()
    local object = { name = "Izel", last_name = "Nakri", points = 32 }
    local call_order = {}
    local operation_result
    Callback.reduce_right(object, function(result, value, callback, key)
      table.insert(call_order, key)
      table.insert(call_order, value)
      Timers.set_timeout(function()
        callback(
          nil,
          vim.tbl_extend("force", result, {
            [key] = value,
          })
        )
      end, 50)
    end, { admin = true }, function(err, result)
      operation_result = result
      assert.are.equal(err, nil)
      assert.are.same(result, {
        admin = true,
        name = "Izel",
        last_name = "Nakri",
        points = 32,
      })
    end)

    wait(350, function()
      assert.are.same(call_order, { "last_name", "Nakri", "name", "Izel", "points", 32 })
      assert.are.same(operation_result, {
        admin = true,
        name = "Izel",
        last_name = "Nakri",
        points = 32,
      })
    end)
  end)

  it("can handle error", function()
    Callback.reduce_right(
      { 1, 2, 3 },
      function(result, value, callback)
        callback("error")
      end,
      0,
      function(err, b)
        assert.are.equal(err, "error")
      end
    )

    wait(300)
  end)

  it("can handle cancel case", function(done)
    local call_order = {}
    Callback.reduce_right(
      { 3, 5, 2 },
      function(result, value, callback, index)
        table.insert(call_order, value)
        if index == 2 then
          callback(false, result + value)
        else
          callback(nil, result + value)
        end
      end,
      0,
      function()
        assert.True(false, "should not get here")
      end
    )

    wait(50, function()
      assert.are.same(call_order, { 2, 5 })
    end)
  end)
end)
