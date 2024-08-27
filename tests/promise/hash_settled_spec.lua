require("async.test")

local Promise = require("promise")

describe("Promise.hash_settled", function()
  async_it("handles a mix of fulfilled and rejected promises", function(done)
    local promises = {
      first = Promise:new(function(resolve)
        resolve("Resolved")
      end),
      second = Promise:new(function(_, reject)
        reject("Rejected")
      end),
    }

    Promise.hash_settled(promises):thenCall(function(results)
      assert.are.same({
        first = { status = "fulfilled", value = "Resolved" },
        second = { status = "rejected", reason = "Rejected" },
      }, results)
      done()
    end)
  end)

  async_it("handles nested promises and values", function(done)
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

    Promise.hash_settled(promises):thenCall(function(results)
      assert.are.same({
        first = { status = "fulfilled", value = { nested = "Nested Resolved" } },
        second = { status = "fulfilled", value = "Resolved" },
      }, results)
      done()
    end)
  end)

  async_it("handles immediate values correctly", function(done)
    local promises = {
      first = "Immediate Value",
      second = Promise:new(function(resolve)
        resolve("Resolved")
      end),
    }

    Promise.hash_settled(promises):thenCall(function(results)
      assert.are.same({
        first = { status = "fulfilled", value = "Immediate Value" },
        second = { status = "fulfilled", value = "Resolved" },
      }, results)
      done()
    end)
  end)

  async_it("handles an empty table correctly", function(done)
    Promise.hash_settled({}):thenCall(function(results)
      assert.are.same({}, results)
      done()
    end)
  end)

  async_it("handles nested rejected promises correctly", function(done)
    local promises = {
      first = Promise:new(function(resolve)
        resolve({ nested = Promise:new(function(_, reject)
          reject("Nested Rejection")
        end) })
      end),
      second = Promise:new(function(resolve)
        resolve("Resolved")
      end),
    }

    Promise.hash_settled(promises):thenCall(function(results)
      assert.are.same({
        first = { status = "fulfilled", value = { nested = { status = "rejected", reason = "Nested Rejection" } } },
        second = { status = "fulfilled", value = "Resolved" },
      }, results)
      done()
    end)
  end)
end)
