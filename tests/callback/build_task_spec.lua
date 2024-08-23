local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.build_task", function()
  after_each(function()
    wait(5)
  end)

  it("works on a waterfall and parallel operations when its a successful sync function", function()
    local multiply = function(a, b)
      return a * b
    end

    Callback.waterfall({
      Callback.build_task(multiply, 2, 3),
      function(value, callback)
        callback(nil, value + 1)
      end,
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 7)
    end)

    Callback.waterfall({
      function(callback)
        return callback(nil, 11)
      end,
      Callback.resolve(22, 2),
      Callback.build_task(multiply),
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 44)
    end)

    Callback.parallel({
      first_op = Callback.build_task(multiply, 3, 5),
      second_op = Callback.build_task(multiply, 2, 3),
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.same(result, { first_op = 15, second_op = 6 })
    end)

    Callback.parallel({
      Callback.build_task(multiply, 2, 5),
      Callback.build_task(multiply, 9, 3),
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.same(result, { 10, 27 })
    end)
  end)

  it("works on a waterfall operation when its an unsuccessful async function", function()
    local multiply = function(a, b)
      error("this is errorrr!: " .. tostring(b), 0)
      return a * b
    end

    Callback.waterfall({
      Callback.build_task(multiply, 2, 3),
      function(value, callback)
        callback(nil, value + 1)
      end,
    }, function(err, result)
      assert.are.equal(err, "this is errorrr!: 3")
      assert.are.equal(result, nil)
    end)

    Callback.waterfall({
      function(callback)
        return callback(nil, 11)
      end,
      Callback.resolve(22, 2),
      Callback.build_task(multiply),
    }, function(err, result)
      assert.are.equal(err, "this is errorrr!: 2")
      assert.are.equal(result, nil)
    end)

    Callback.parallel({
      first_op = function(callback)
        callback(nil, 55)
      end,
      second_op = Callback.build_task(multiply, 2, 3),
    }, function(err, result)
      assert.are.equal(err, "this is errorrr!: 3")
      assert.are.same(result, { first_op = 55, second_op = {} })
    end)

    Callback.parallel({
      function(callback)
        callback(nil, 55)
      end,
      Callback.build_task(multiply, 9, 3),
    }, function(err, result)
      assert.are.equal(err, "this is errorrr!: 3")
      assert.are.same(result, { 55, {} })
    end)
  end)
end)
