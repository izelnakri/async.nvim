local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.resolve", function()
  after_each(function()
    wait(5)
  end)

  it("basic usage", function()
    Callback.resolve(42, 1, 2, 3)(function(err, value, a, b, c)
      assert.are.equal(err, nil)
      assert.are.equal(value, 42)
      assert.are.equal(a, 1)
      assert.are.equal(b, 2)
      assert.are.equal(c, 3)
    end)
  end)

  it("called with multiple arguments", function()
    Callback.resolve(42, 1, 2, 3)("argument to ignore", "another argument", function(err, value, a, b, c, d, e, f)
      assert.are.equal(err, nil)
      assert.are.equal(value, 42)
      assert.are.equal(a, 1)
      assert.are.equal(a, 1)
    end)
  end)

  it("can be used in a waterfall correctly", function()
    Callback.waterfall({
      Callback.resolve(42),
      function(value, next)
        next(nil, value + 1)
      end,
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 43)
    end)

    Callback.waterfall({
      function(callback)
        callback(nil, 11)
      end,
      Callback.resolve(22),
      function(value, next)
        next(nil, value + 1)
      end,
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 23)
    end)

    local async_add = Callback.build(function(...)
      local result = 0
      for _, value in pairs({ ... }) do
        result = result + value
      end

      return result
    end)

    Callback.waterfall({
      Callback.resolve(3, 4),
      async_add,
      function(value, next)
        next(nil, value + 1)
      end,
      Callback.apply(async_add, 2),
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 10)
    end)
  end)

  it("can pass stable value on each_series", function()
    Callback.each_series(
      {
        "a",
        "b",
        "c",
      },
      Callback.resolve("lol"),
      function(err, result)
        assert.are.equal(err, nil)
        assert.are.equal(result, "lol")
      end
    )
  end)
end)
