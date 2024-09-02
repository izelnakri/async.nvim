require("async.test")

local Promise = require("promise")

describe("Promise.waterfall", function()
  async_it("resolves promises in sequence", function(done)
    local tasks = {
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(1)
          end, 50)
        end)
      end,
      function(result)
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(result + 1)
          end, 50)
        end)
      end,
      function(result)
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(result * 2)
          end, 50)
        end)
      end,
    }

    Promise.waterfall(tasks)
      :and_then(function(result)
        assert.are.equal(4, result)
        done()
      end)
      :catch(function()
        error("Promise.waterfall should not reject if all tasks resolve.")
      end)
  end)

  async_it("handles rejection correctly", function(done)
    local tasks = {
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(1)
          end, 50)
        end)
      end,
      function(result)
        return Promise:new(function(_, reject)
          vim.defer_fn(function()
            reject("Error in second task")
          end, 50)
        end)
      end,
      function(result)
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(result + 1)
          end, 50)
        end)
      end,
    }

    Promise.waterfall(tasks)
      :catch(function(err)
        assert.are.equal("Error in second task", err)
        done()
      end)
      :and_then(function()
        error("Promise.waterfall should not resolve if a task rejects.")
      end)
  end)

  async_it("resolves immediately with empty tasks", function(done)
    Promise.waterfall({})
      :and_then(function(result)
        assert.are.equal(nil, result)
        done()
      end)
      :catch(function()
        error("Promise.waterfall should not reject with empty tasks.")
      end)
  end)

  async_it("throws an error if a function does not return a promise", function(done)
    local tasks = {
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(1)
          end, 50)
        end)
      end,
      function(result)
        return result + 1 -- Not a promise
      end,
      function(result)
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(result * 2)
          end, 50)
        end)
      end,
    }

    Promise.waterfall(tasks)
      :catch(function(err)
        assert.is_true(string.find(err, "Promise.waterfall: all functions must return a promise") ~= nil)
        done()
      end)
      :and_then(function()
        error("Promise.waterfall should not resolve if a task does not return a promise.")
      end)
  end)

  -- NOTE: FIX this:
  async_it("handles errors thrown in the task functions", function(done)
    local tasks = {
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(1)
          end, 50)
        end)
      end,
      function(result)
        error("Error in second task")
      end,
      function(result)
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(result * 2)
          end, 50)
        end)
      end,
    }

    Promise.waterfall(tasks)
      :catch(function(err)
        assert.has.match("Error in second task", err)
        done()
      end)
      :and_then(function()
        error("Promise.waterfall should not resolve if a task throws an error.")
      end)
  end)

  async_it("handles nested promises correctly", function(done)
    local tasks = {
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(1)
          end, 50)
        end)
      end,
      function(result)
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(Promise:new(function(resolve)
              vim.defer_fn(function()
                resolve(result + 1)
              end, 50)
            end))
          end, 50)
        end)
      end,
      function(result)
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(result * 2)
          end, 50)
        end)
      end,
    }

    Promise.waterfall(tasks)
      :and_then(function(result)
        assert.are.equal(4, result)
        done()
      end)
      :catch(function()
        error("Promise.waterfall should not reject if all nested tasks resolve.")
      end)
  end)
end)
