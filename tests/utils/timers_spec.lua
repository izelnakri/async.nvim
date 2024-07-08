local Timers = require("callback.utils.timers")

describe("Timers", function()
  describe("set_interval", function()
    it("should call the function multiple times at the specified interval", function()
      local count = 0
      local timer = Timers.set_interval(function(interval)
        count = count + 1
        assert.equals(100, interval)
        if count == 3 and timer then -- NOTE: This gets called multiple times(?)
          Timers.clear_interval(timer)
        end
      end, 100)

      vim.wait(350, function()
        return count == 3
      end)
      assert.equals(3, count)
    end)
  end)

  describe("set_timeout", function()
    it("should call the function once after the specified delay", function()
      local called = false
      Timers.set_timeout(function(timeout)
        called = true
        assert.equals(200, timeout)
      end, 200)

      vim.wait(250, function()
        return called
      end)
      assert.is_true(called)
    end)
  end)

  describe("clear_interval", function()
    it("should prevent further calls of the interval function", function()
      local count = 0
      local timer = Timers.set_interval(function()
        count = count + 1
      end, 100)

      Timers.clear_interval(timer)

      vim.wait(250)
      assert.equals(0, count)
    end)
  end)

  describe("clear_timeout", function()
    it("should prevent the timeout function from being called", function()
      local called = false
      local timer = Timers.set_timeout(function()
        called = true
      end, 200)

      Timers.clear_timeout(timer)

      vim.wait(250)
      assert.is_false(called)
    end)
  end)
end)
