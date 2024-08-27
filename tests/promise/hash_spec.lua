require("async.test")

local Promise = require("promise")

describe("Promise.hash", function()
  async_it("resolves when all promises resolve", function(done)
    local promises = {
      first = Promise:new(function(resolve)
        resolve(1)
      end),
      second = Promise:new(function(resolve)
        resolve(2)
      end),
      third = Promise:new(function(resolve)
        resolve(3)
      end),
    }

    Promise.hash(promises)
      :thenCall(function(results)
        assert.are.same({ first = 1, second = 2, third = 3 }, results)
        done()
      end)
      :catch(function()
        error("Promise.hash should not reject when all promises resolve.")
      end)
  end)

  async_it("rejects when any promise rejects", function(done)
    local promises = {
      first = Promise:new(function(resolve)
        resolve(1)
      end),
      second = Promise:new(function(_, reject)
        reject("Error in second promise")
      end),
      third = Promise:new(function(resolve)
        resolve(3)
      end),
    }

    Promise.hash(promises)
      :thenCall(function()
        error("Promise.hash should not resolve when one promise rejects.")
      end)
      :catch(function(reason)
        assert.are.equal("Error in second promise", reason)
        done()
      end)
  end)

  async_it("handles non-promise values correctly", function(done)
    local promises = {
      first = 1,
      second = Promise:new(function(resolve)
        resolve(2)
      end),
      third = "non-promise",
    }

    Promise.hash(promises)
      :thenCall(function(results)
        assert.are.same({ first = 1, second = 2, third = "non-promise" }, results)
        done()
      end)
      :catch(function()
        error("Promise.hash should not reject for non-promise values.")
      end)
  end)

  async_it("resolves immediately with an empty hash", function(done)
    Promise.hash({})
      :thenCall(function(results)
        assert.are.same({}, results)
        done()
      end)
      :catch(function()
        error("Promise.hash should not reject for an empty hash.")
      end)
  end)

  async_it("handles nested promises correctly", function(done)
    local promises = {
      first = Promise:new(function(resolve)
        resolve(Promise:new(function(resolve)
          resolve(1)
        end))
      end),
      second = Promise:new(function(resolve)
        resolve(2)
      end),
    }

    Promise.hash(promises)
      :thenCall(function(results)
        assert.are.same({
          first = 1,
          second = 2,
        }, results)
        done()
      end)
      :catch(function()
        error("Promise.hash should not reject for nested promises.")
      end)
  end)

  async_it("maintains the order of keys in the resulting hash", function(done)
    local promises = {
      b = Promise:new(function(resolve)
        vim.defer_fn(function()
          resolve("B")
        end, 100)
      end),
      a = Promise:new(function(resolve)
        vim.defer_fn(function()
          resolve("A")
        end, 50)
      end),
    }

    Promise.hash(promises)
      :thenCall(function(results)
        assert.are.same({ b = "B", a = "A" }, results)
        done()
      end)
      :catch(function()
        error("Promise.hash should not reject when promises resolve in different orders.")
      end)
  end)

  async_it("rejects immediately if the first promise rejects", function(done)
    local promises = {
      first = Promise:new(function(_, reject)
        reject("First Error")
      end),
      second = Promise:new(function(resolve)
        resolve(2)
      end),
    }

    Promise.hash(promises)
      :thenCall(function()
        error("Promise.hash should not resolve when the first promise rejects.")
      end)
      :catch(function(reason)
        assert.are.equal("First Error", reason)
        done()
      end)
  end)

  async_it("resolves nested non-promise values correctly", function(done)
    local promises = {
      first = Promise:new(function(resolve)
        resolve({ nested = Promise:new(function(resolve)
          resolve("Nested Resolved")
        end) })
      end),
      second = Promise:new(function(resolve)
        resolve("Resolved")
      end),
    }

    Promise.hash(promises)
      :thenCall(function(results)
        assert.are.same({
          first = { nested = "Nested Resolved" },
          second = "Resolved",
        }, results)
        done()
      end)
      :catch(function(err)
        error("Promise.hash should not reject for nested non-promise values.")
      end)
  end)
end)
