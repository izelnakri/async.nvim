require("async.test")

local Callback = require("callback")
local Timers = require("timers")

describe("Callback.all", function()
  async_it("works with timeout", function()
    vim.print("RUNNIN SOMETHING")
    vim.print("")

    Timers.set_timeout(function()
      assert.are.equal(true, true)
      done()
    end, 1000)
  end)

  async_it("with no callbacks working", function()
    vim.print("XRUNNIN SOMETHING")
    vim.print("")
    assert.are.equal(true, true)
    done()
  end)

  async_it("another one with timeout", function()
    Timers.set_timeout(function()
      vim.print("CXXX")
      assert.are.equal("A", "A")

      done() -- Calls done_callback to unblock the async_it
    end, 1000)
    vim.print("AAAAAAAAA")

    assert.are.equal("A", "A")
  end)

  async_it("testing Callback.parallel", function()
    vim.print("CALLING SECOND")
    vim.print("")

    Callback.parallel({
      function(callback)
        return callback(nil, 33)
      end,
      function(callback)
        Timers.set_timeout(function()
          callback(nil, "second")
        end, 5000)
      end,
      function(callback)
        Timers.set_timeout(function()
          callback(nil, "third")
        end, 300)
      end,
    }, function(result)
      vim.print("RESULT IS:")
      vim.print(result)
      vim.print("")

      assert.are.equal("2AA", "2AA")

      done() -- Calls done_callback to unblock the async_it
    end)

    vim.print("cool")
    vim.print("")

    assert.are.equal("AA", "AA") -- TODO: This should fail
  end)

  async_it("with async uv function works", function()
    vim.uv.fs_statfs("./stylua.toml", function(err, res)
      assert.are.equal(true, true)
      done()
    end)
  end)

  async_it("runtime error on sync code works", function()
    Timer.set_timeout(function()
      vim.print("CXXX")
      assert.are.equal("A", "A")

      done()
    end, 1000)
    vim.print("AAAAAAAAA")

    assert.are.equal("A", "A")
  end)

  async_it("runtime errors on async code works", function()
    Timers.set_timeout(function()
      Timer.set_timeout()
      vim.print("CXXX")
      assert.are.equal("A", "A")

      done()
    end, 1000)
    vim.print("AAAAAAAAA")

    assert.are.equal("A", "A")
  end)

  async_it("with defer function works", function()
    vim.defer_fn(function()
      print("zXXX")
      assert.are.equal("A", "A")

      done()
    end, 1000)
    print("zAAAAAAAA")

    assert.are.equal("A", "A")
  end)
end)
