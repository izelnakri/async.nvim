local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.build", function()
  after_each(function()
    wait(5)
  end)

  it("can turn a sync functions with no errors to a callback based function", function()
    local add = function(...)
      local result = 0
      for _, param in pairs({ ... }) do
        result = result + param
      end

      return result
    end

    local async_add_with_params = Callback.build(add, 3, 2, 1)

    async_add_with_params(10, 22, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 38)
    end)

    Callback.build(add)(30, 11, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 41)
    end)

    local multiply = function(a, b)
      return a * b
    end
    local multiply_async = Callback.build(multiply)
    multiply_async(2, 4, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 8)
    end)

    local multiply_async_curried = Callback.build(multiply, 12)
    multiply_async_curried(3, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 36)
    end)
  end)

  it("can turn a sync functions with errors to a callback based function", function()
    local add = function(...)
      local result = 0
      for _, param in pairs({ ... }) do
        result = result + param
      end

      error(result, 0)

      return {}
    end

    local async_add_with_params = Callback.build(add, 3, 2, 1)

    async_add_with_params(10, 22, function(err, result)
      assert.are.equal(err, 38)
      assert.are.equal(result, nil)
    end)

    Callback.build(add)(30, 11, function(err, result)
      assert.are.equal(err, 41)
      assert.are.equal(result, nil)
    end)

    local multiply = function(a, b)
      error(a * b, 0)

      return a * b
    end
    local multiply_async = Callback.build(multiply)
    multiply_async(2, 4, function(err, result)
      assert.are.equal(err, 8)
      assert.are.equal(result, nil)
    end)

    local multiply_async_curried = Callback.build(multiply, 12)
    multiply_async_curried(3, function(err, result)
      assert.are.equal(err, 36)
      assert.are.equal(result, nil)
    end)
  end)
end)
