-- local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")

-- NOTE: check diff between vim.schedule vs vim.schedule_fn
describe("Callback.forever function is sync", function()
  it("executes the function over and over until it yields an error", function()
    local counter = 0
    local add_one = function(callback)
      counter = counter + 1
      if counter == 50000 then
        return callback("too big!")
      end

      callback()
    end

    Callback.forever(add_one, function(err)
      assert.are.equal(err, "too big!")
      assert.are.equal(counter, 50000)
    end)

    wait(50)
  end)

  it("can be cancelled", function()
    local counter = 0
    Callback.forever(function(callback)
      counter = counter + 1
      if counter == 2 then
        callback(false)
      else
        callback()
      end
    end, function()
      assert.True(false, "it should not get here")
    end)

    wait(10, function()
      assert.are.equal(counter, 2)
    end)
  end)
end)

describe("Callback.forever function is async", function()
  it("executes the function over and over until it yields an error", function()
    local counter = 0
    local add_one = function(callback)
      counter = counter + 1
      if counter == 50000 then
        return vim.schedule(function()
          callback("too big!")
        end)
      end

      vim.schedule(function()
        callback()
      end)
    end

    Callback.forever(add_one, function(err)
      assert.are.equal(err, "too big!")
      assert.are.equal(counter, 50000)
    end)

    wait(50)
  end)

  it("can be cancelled", function()
    local counter = 0
    Callback.forever(function(callback)
      counter = counter + 1
      if counter == 2 then
        vim.schedule(function()
          callback(false)
        end)
      else
        vim.schedule(function()
          callback()
        end)
      end
    end, function()
      assert.True(false, "it should not get here")
    end)

    wait(10, function()
      assert.are.equal(counter, 2)
    end)
  end)
end)
