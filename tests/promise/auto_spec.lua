require("async.test")

local Promise = require("promise")

describe("Promise.auto", function()
  async_it("runs tasks without dependencies in parallel", function(done)
    local tasks = {
      task1 = {
        function()
          return Promise:new(function(resolve)
            vim.defer_fn(function()
              resolve("Result from task1")
            end, 100)
          end)
        end,
      },
      task2 = {
        function()
          return Promise:new(function(resolve)
            vim.defer_fn(function()
              resolve("Result from task2")
            end, 50)
          end)
        end,
      },
    }

    Promise.auto(tasks):and_then(function(results)
      assert.are.same({
        task1 = "Result from task1",
        task2 = "Result from task2",
      }, results)
      done()
    end)
  end)

  async_it("runs tasks with dependencies in the correct order", function(done)
    local tasks = {
      task1 = {
        function()
          return Promise:new(function(resolve)
            vim.defer_fn(function()
              resolve("Result from task1")
            end, 100)
          end)
        end,
      },
      task2 = {
        "task1",
        function(result_from_task1)
          return Promise:new(function(resolve)
            vim.defer_fn(function()
              resolve(result_from_task1 .. " -> Result from task2")
            end, 50)
          end)
        end,
      },
      task3 = {
        "task2",
        function(result_from_task2)
          return Promise:new(function(resolve)
            vim.defer_fn(function()
              resolve(result_from_task2 .. " -> Result from task3")
            end, 150)
          end)
        end,
      },
    }

    Promise.auto(tasks):and_then(function(results)
      assert.are.same({
        task1 = "Result from task1",
        task2 = "Result from task1 -> Result from task2",
        task3 = "Result from task1 -> Result from task2 -> Result from task3",
      }, results)
      done()
    end)
  end)

  async_it("handles tasks with multiple dependencies", function(done)
    local tasks = {
      task1 = {
        function()
          return Promise:new(function(resolve)
            vim.defer_fn(function()
              resolve("Result from task1")
            end, 100)
          end)
        end,
      },
      task2 = {
        function()
          return Promise:new(function(resolve)
            vim.defer_fn(function()
              resolve("Result from task2")
            end, 50)
          end)
        end,
      },
      task3 = {
        "task1",
        "task2",
        function(result_from_task1, result_from_task2)
          return Promise:new(function(resolve)
            vim.defer_fn(function()
              resolve(result_from_task1 .. " & " .. result_from_task2 .. " -> Result from task3")
            end, 75)
          end)
        end,
      },
    }

    Promise.auto(tasks):and_then(function(results)
      assert.are.same({
        task1 = "Result from task1",
        task2 = "Result from task2",
        task3 = "Result from task1 & Result from task2 -> Result from task3",
      }, results)
      done()
    end)
  end)

  async_it("handles tasks with no dependencies", function(done)
    local tasks = {
      task1 = {
        function()
          return Promise:new(function(resolve)
            vim.defer_fn(function()
              resolve("Result from task1")
            end, 100)
          end)
        end,
      },
      task2 = {
        function()
          return Promise:new(function(resolve)
            vim.defer_fn(function()
              resolve("Result from task2 with no dependencies")
            end, 50)
          end)
        end,
      },
    }

    Promise.auto(tasks):and_then(function(results)
      assert.are.same({
        task1 = "Result from task1",
        task2 = "Result from task2 with no dependencies",
      }, results)
      done()
    end)
  end)

  async_it("throws an error for circular dependencies", function()
    local tasks = {
      task1 = { "task2", function() end },
      task2 = { "task1", function() end },
    }

    Promise.auto(tasks):and_then(function() end):catch(function(err)
      assert.has.match("Circular dependency detected", err)
      done()
    end)
  end)

  it("throws an error if a task depends on a non-existent task", function()
    local tasks = {
      task1 = { "task2", function() end },
    }

    Promise.auto(tasks):and_then(function() end):catch(function(err)
      assert.has.match("Task 'task2' not found", err)
      done()
    end)
  end)

  async_it("handles errors in tasks", function(done)
    local tasks = {
      task1 = {
        function()
          return Promise:new(function(_, reject)
            vim.defer_fn(function()
              reject("Error in task1")
            end, 100)
          end)
        end,
      },
      task2 = {
        "task1",
        function()
          return Promise:new(function(resolve)
            vim.defer_fn(function()
              resolve("Result from task2")
            end, 50)
          end)
        end,
      },
    }

    Promise.auto(tasks)
      :and_then(function()
        -- This should not be called
        error("Promise.auto should not resolve when a task fails")
      end)
      :catch(function(err)
        assert.are.equal("Error in task1", err)
        done()
      end)
  end)

  async_it("executes tasks that are ready immediately", function(done)
    local tasks = {
      task1 = {
        function()
          return Promise.resolve("Result from task1")
        end,
      },
      task2 = {
        "task1",
        function(result_from_task1)
          return Promise.resolve(result_from_task1 .. " -> Result from task2")
        end,
      },
      task3 = {
        "task2",
        function(result_from_task2)
          return Promise.resolve(result_from_task2 .. " -> Result from task3")
        end,
      },
    }

    Promise.auto(tasks):and_then(function(results)
      assert.are.same({
        task1 = "Result from task1",
        task2 = "Result from task1 -> Result from task2",
        task3 = "Result from task1 -> Result from task2 -> Result from task3",
      }, results)
      done()
    end)
  end)
end)
