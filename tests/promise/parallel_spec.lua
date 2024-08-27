require("async.test")

local Promise = require("promise")

describe("Promise.parallel", function()
  async_it("resolves all promises in parallel", function(done)
    local tasks = {
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(1)
          end, 100)
        end)
      end,
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(2)
          end, 50)
        end)
      end,
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(3)
          end, 150)
        end)
      end,
    }

    Promise.parallel(tasks)
      :thenCall(function(results)
        assert.are.same({ 1, 2, 3 }, results)
        done()
      end)
      :catch(function(err)
        error("Promise.parallel should not reject: " .. err)
      end)
  end)

  async_it("rejects if any promise rejects", function(done)
    local tasks = {
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(1)
          end, 100)
        end)
      end,
      function()
        return Promise:new(function(_, reject)
          vim.defer_fn(function()
            reject("Error in second task")
          end, 50)
        end)
      end,
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(3)
          end, 150)
        end)
      end,
    }

    Promise.parallel(tasks)
      :thenCall(function(results)
        error("Promise.parallel should have rejected")
      end)
      :catch(function(err)
        assert.are.equal("Error in second task", err)
        done()
      end)
  end)

  async_it("resolves immediately if given an empty list", function(done)
    Promise.parallel({})
      :thenCall(function(results)
        assert.are.same({}, results)
        done()
      end)
      :catch(function(err)
        error("Promise.parallel should not reject: " .. err)
      end)
  end)

  async_it("handles a mix of synchronous and asynchronous promises", function(done)
    local tasks = {
      function()
        return Promise:new(function(resolve)
          resolve(1) -- Synchronous resolution
        end)
      end,
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(2)
          end, 100)
        end)
      end,
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(3)
          end, 50)
        end)
      end,
    }

    Promise.parallel(tasks)
      :thenCall(function(results)
        assert.are.same({ 1, 2, 3 }, results)
        done()
      end)
      :catch(function(err)
        error("Promise.parallel should not reject: " .. err)
      end)
  end)

  async_it("rejects immediately if a task does not return a promise", function(done)
    local tasks = {
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(1)
          end, 100)
        end)
      end,
      function()
        return 2 -- This is not a promise
      end,
      function()
        return Promise:new(function(resolve)
          vim.defer_fn(function()
            resolve(3)
          end, 50)
        end)
      end,
    }

    Promise.parallel(tasks)
      :thenCall(function(results)
        error("Promise.parallel should have rejected")
      end)
      :catch(function(err)
        assert.are.equal("Promise.parallel: all functions must return a promise", err)
        done()
      end)
  end)
end)
