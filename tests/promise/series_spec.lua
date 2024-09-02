require("async.test")

local Promise = require("promise") -- Replace with your actual Promise module

describe("Promise.series", function()
  async_it("executes functions sequentially and collects results", function(done)
    local call_order = {}

    local function task1()
      table.insert(call_order, "task1")
      return Promise:new(function(resolve)
        vim.defer_fn(function()
          resolve("Result 1")
        end, 100)
      end)
    end

    local function task2()
      table.insert(call_order, "task2")
      return Promise:new(function(resolve)
        vim.defer_fn(function()
          resolve("Result 2")
        end, 200)
      end)
    end

    Promise.series({ task1, task2 })
      :and_then(function(results)
        assert.are.same({ "Result 1", "Result 2" }, results)
        assert.are.same({ "task1", "task2" }, call_order)
        done()
      end)
      :catch(function(err)
        error("Promise.series should not reject on successful tasks")
      end)
  end)

  async_it("rejects if any promise rejects", function(done)
    local function task1()
      return Promise:new(function(resolve)
        vim.defer_fn(function()
          resolve("Result 1")
        end, 100)
      end)
    end

    local function task2()
      return Promise:new(function(_, reject)
        vim.defer_fn(function()
          reject("Error in task2")
        end, 200)
      end)
    end

    Promise.series({ task1, task2 })
      :and_then(function()
        error("Promise.series should not resolve if any promise rejects")
      end)
      :catch(function(err)
        assert.are.equal("Error in task2", err)
        done()
      end)
  end)

  async_it("resolves immediately with an empty input list", function(done)
    Promise.series({})
      :and_then(function(results)
        assert.are.same({}, results)
        done()
      end)
      :catch(function()
        error("Promise.series should not reject on empty input")
      end)
  end)

  async_it("rejects if a function does not return a promise", function(done)
    local function task1()
      return "Not a promise"
    end

    Promise.series({ task1 })
      :and_then(function()
        error("Promise.series should reject if a function does not return a promise")
      end)
      :catch(function(err)
        assert.are.same("Promise.series: all functions must return a promise", err)
        done()
      end)
  end)

  async_it("rejects if a function throws an error", function(done)
    local function task1()
      return Promise:new(function(resolve)
        vim.defer_fn(function()
          resolve("Result 1")
        end, 100)
      end)
    end

    local function task2()
      error("Error in task2")
    end

    Promise.series({ task1, task2 })
      :and_then(function()
        error("Promise.series should not resolve if a function throws an error")
      end)
      :catch(function(err)
        assert.has.match("Error in task2", err)
        done()
      end)
  end)
end)
