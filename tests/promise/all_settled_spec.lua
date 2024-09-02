require("async.test")

local Promise = require("promise")

describe("Promise.Promise.all_settled", function()
  async_it("resolves when all promises resolve", function(done)
    local promise1 = Promise:new(function(resolve)
      resolve(1)
    end)
    local promise2 = Promise:new(function(resolve)
      resolve(2)
    end)
    local promise3 = Promise:new(function(resolve)
      resolve(3)
    end)

    Promise.all_settled({ promise1, promise2, promise3 })
      :and_then(function(results)
        assert.are.same({
          { status = "fulfilled", value = 1 },
          { status = "fulfilled", value = 2 },
          { status = "fulfilled", value = 3 },
        }, results)
        done()
      end)
      :catch(function()
        error("Promise.Promise.all_settled should not reject when all promises resolve.")
      end)
  end)

  async_it("resolves when all promises reject", function(done)
    local promise1 = Promise:new(function(_, reject)
      reject("Error 1")
    end)
    local promise2 = Promise:new(function(_, reject)
      reject("Error 2")
    end)
    local promise3 = Promise:new(function(_, reject)
      reject("Error 3")
    end)

    Promise.all_settled({ promise1, promise2, promise3 })
      :and_then(function(results)
        assert.are.same({
          { status = "rejected", value = "Error 1" },
          { status = "rejected", value = "Error 2" },
          { status = "rejected", value = "Error 3" },
        }, results)
        done()
      end)
      :catch(function()
        error("Promise.Promise.all_settled should not reject when all promises reject.")
      end)
  end)

  async_it("resolves with mixed resolved and rejected promises", function(done)
    local promise1 = Promise:new(function(resolve)
      resolve(1)
    end)
    local promise2 = Promise:new(function(_, reject)
      reject("Error 2")
    end)
    local promise3 = Promise:new(function(resolve)
      resolve(3)
    end)

    Promise.all_settled({ promise1, promise2, promise3 })
      :and_then(function(results)
        assert.are.same({
          { status = "fulfilled", value = 1 },
          { status = "rejected", value = "Error 2" },
          { status = "fulfilled", value = 3 },
        }, results)
        done()
      end)
      :catch(function()
        error("Promise.Promise.all_settled should not reject with mixed promises.")
      end)
  end)

  async_it("resolves non-promise values immediately", function(done)
    local value1 = 1
    local promise1 = Promise:new(function(resolve)
      resolve(2)
    end)
    local value2 = 3

    Promise.all_settled({ value1, promise1, value2 })
      :and_then(function(results)
        assert.are.same({
          { status = "fulfilled", value = 1 },
          { status = "fulfilled", value = 2 },
          { status = "fulfilled", value = 3 },
        }, results)
        done()
      end)
      :catch(function()
        error("Promise.Promise.all_settled should not reject for non-promise values.")
      end)
  end)

  async_it("resolves immediately with an empty array", function(done)
    Promise.all_settled({})
      :and_then(function(results)
        assert.are.same({}, results)
        done()
      end)
      :catch(function()
        error("Promise.Promise.all_settled should not reject for an empty array.")
      end)
  end)

  async_it("handles delayed promises correctly", function(done)
    local promise1 = Promise:new(function(resolve)
      vim.defer_fn(function()
        resolve(1)
      end, 100)
    end)

    local promise2 = Promise:new(function(_, reject)
      vim.defer_fn(function()
        reject("Error 2")
      end, 50)
    end)

    local promise3 = Promise:new(function(resolve)
      vim.defer_fn(function()
        resolve(3)
      end, 150)
    end)

    Promise.all_settled({ promise1, promise2, promise3 })
      :and_then(function(results)
        assert.are.same({
          { status = "fulfilled", value = 1 },
          { status = "rejected", value = "Error 2" },
          { status = "fulfilled", value = 3 },
        }, results)
        done()
      end)
      :catch(function()
        error("Promise.Promise.all_settled should not reject when handling delayed promises.")
      end)
  end)

  async_it("handles single resolved promise", function(done)
    local promise = Promise:new(function(resolve)
      resolve(1)
    end)

    Promise.all_settled({ promise })
      :and_then(function(results)
        assert.are.same({
          { status = "fulfilled", value = 1 },
        }, results)
        done()
      end)
      :catch(function()
        error("Promise.Promise.all_settled should not reject for a single resolved promise.")
      end)
  end)

  async_it("handles single rejected promise", function(done)
    local promise = Promise:new(function(_, reject)
      reject("Error 1")
    end)

    Promise.all_settled({ promise })
      :and_then(function(results)
        assert.are.same({
          { status = "rejected", value = "Error 1" },
        }, results)
        done()
      end)
      :catch(function()
        error("Promise.Promise.all_settled should not reject for a single rejected promise.")
      end)
  end)

  async_it("handles complex objects correctly", function(done)
    local promise1 = Promise:new(function(resolve)
      resolve({ key = "value" })
    end)
    local complexObject = { nested = { 1, 2, 3 }, key = "value" }

    Promise.all_settled({ promise1, complexObject })
      :and_then(function(results)
        assert.are.same({
          { status = "fulfilled", value = { key = "value" } },
          { status = "fulfilled", value = { nested = { 1, 2, 3 }, key = "value" } },
        }, results)
        done()
      end)
      :catch(function()
        error("Promise.allSettled should not reject for complex objects.")
      end)
  end)

  async_it("handles promise-like objects correctly", function(done)
    local promiseLike = {
      and_then = function(self, onFulfilled, onRejected)
        onFulfilled(42)
      end,
    }

    local promise1 = Promise:new(function(resolve)
      resolve(1)
    end)

    Promise.all_settled({ promise1, promiseLike })
      :and_then(function(results)
        assert.are.same({
          { status = "fulfilled", value = 1 },
          { status = "fulfilled", value = 42 },
        }, results)
        done()
      end)
      :catch(function()
        error("Promise.allSettled should not reject for promise-like objects.")
      end)
  end)

  async_it("handles rejected promise-like objects correctly", function(done)
    local promiseLike = {
      and_then = function(self, onFulfilled, onRejected)
        onRejected("Rejected by promise-like")
      end,
    }

    local promise1 = Promise:new(function(resolve)
      resolve(1)
    end)

    Promise.all_settled({ promise1, promiseLike })
      :and_then(function(results)
        assert.are.same({
          { status = "fulfilled", value = 1 },
          { status = "rejected", value = "Rejected by promise-like" },
        }, results)
        done()
      end)
      :catch(function()
        error("Promise.allSettled should not reject for promise-like objects.")
      end)
  end)

  async_it("handles nested promises correctly", function(done)
    local promise1 = Promise:new(function(resolve)
      resolve(Promise:new(function(resolve)
        resolve(1)
      end))
    end)

    local promise2 = Promise:new(function(_, reject)
      reject(Promise:new(function(_, reject)
        reject("Nested rejection")
      end))
    end)

    Promise.all_settled({ promise1, promise2 })
      :and_then(function(results)
        assert.are.same(results[1].status, "fulfilled")
        assert.are.same(results[2].status, "rejected")
        done()
      end)
      :catch(function(err)
        error("Promise.allSettled should not reject for nested promises.")
      end)
  end)
end)
