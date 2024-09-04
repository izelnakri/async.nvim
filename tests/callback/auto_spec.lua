require("async.test")

local Callback = require("callback")
local List = require("callback.utils.list")
local Object = require("callback.utils.object")
local null = require("callback.types.null")
local Timers = require("timers")
local deep_equal = require("tests.utils.deep_equal")
local wait = require("tests.utils.wait")

describe("Callback.auto", function()
  after_each(function()
    wait(80)
  end)

  async_it("works for a basic case", function(done)
    local call_order = {}

    Callback.auto({
      task1 = {
        "task2",
        function(results, callback)
          Timers.set_timeout(function()
            table.insert(call_order, "task1")
            callback()
          end, 25)
        end,
      },
      task2 = function(callback)
        Timers.set_timeout(function()
          table.insert(call_order, "task2")
          callback()
        end, 50)
      end,
      task3 = {
        "task2",
        function(results, callback)
          table.insert(call_order, "task3")
          callback()
        end,
      },
      task4 = {
        "task1",
        "task2",
        function(results, callback)
          table.insert(call_order, "task4")
          callback()
        end,
      },
      task5 = {
        "task2",
        function(results, callback)
          Timers.set_timeout(function()
            table.insert(call_order, "task5")
            callback()
          end, 0)
        end,
      },
      task6 = {
        "task2",
        function(results, callback)
          table.insert(call_order, "task6")
          callback()
        end,
      },
    }, function(err)
      assert.are.equal(err, nil)
      deep_equal(call_order, { "task2", "task3", "task6", "task5", "task1", "task4" })
      done()
    end)
  end)

  async_it("auto concurrency", function()
    local concurrency = 2
    local running_tasks = {}

    function make_callback(task_name)
      return function(...) -- /*..., callback*/
        local arguments = { ... }
        local callback = arguments[#arguments]

        List.push(running_tasks, task_name)

        Timers.set_timeout(function()
          -- Each task returns the array of running tasks as results.
          local result = List.slice(running_tasks, 1)
          local target_index = List.index_of(running_tasks, task_name)

          table.remove(running_tasks, target_index)
          -- runningTasks.splice(runningTasks.indexOf(taskName), 1);

          callback(nil, result)
        end)
      end
    end

    Callback.auto(
      {
        task1 = { "task2", make_callback("task1") },
        task2 = make_callback("task2"),
        task3 = { "task2", make_callback("task3") },
        task4 = { "task1", "task2", make_callback("task4") },
        task5 = { "task2", make_callback("task5") },
        task6 = { "task2", make_callback("task6") },
      },
      concurrency,
      function(err, results)
        Object.values(results):each(function(result)
          vim.print(vim.inspect(result))
          assert.True(#result < (concurrency + 1))
        end)
        done()
      end
    )
  end)

  async_it("auto petrify", function()
    local call_order = {}
    Callback.auto({
      task1 = {
        "task2",
        function(results, callback)
          Timers.set_timeout(function()
            List.push(call_order, "task1")
            callback()
          end, 100)
        end,
      },
      task2 = function(callback)
        Timers.set_timeout(function()
          List.push(call_order, "task2")
          callback()
        end, 200)
      end,
      task3 = {
        "task2",
        function(results, callback)
          List.push(call_order, "task3")
          callback()
        end,
      },
      task4 = {
        "task1",
        "task2",
        function(results, callback)
          List.push(call_order, "task4")
          callback()
        end,
      },
    }, function(err)
      if err then
        assert.True(false, "should be no errors")
      end
      assert.are.same(call_order, { "task2", "task3", "task1", "task4" })
      done()
    end)
  end)

  async_it("auto results", function()
    local call_order = {}
    Callback.auto({
      task1 = {
        "task2",
        function(results, callback)
          assert.are.equal(results.task2, "task2")
          Timers.set_timeout(function()
            List.push(call_order, "task1")
            callback(nil, "task1a", "task1b")
          end, 25)
        end,
      },
      task2 = function(callback)
        Timers.set_timeout(function()
          List.push(call_order, "task2")
          callback(nil, "task2")
        end, 50)
      end,
      task3 = {
        "task2",
        function(results, callback)
          assert.are.equal(results.task2, "task2")
          List.push(call_order, "task3")
          callback(nil)
        end,
      },
      task4 = {
        "task1",
        "task2",
        function(results, callback)
          deep_equal(results.task1, { "task1a", "task1b" })
          assert.are.equal(results.task2, "task2")
          List.push(call_order, "task4")
          callback(nil, "task4")
        end,
      },
    }, function(err, results)
      assert.are.same(call_order, { "task2", "task3", "task1", "task4" })
      assert.are.same(results, {
        task1 = { "task1a", "task1b" },
        task2 = "task2",
        task3 = null,
        task4 = "task4",
      })
      done()
    end)
  end)

  async_it("works on empty objects", function()
    Callback.auto({}, function()
      Callback.auto({}, function(err, result)
        assert.are.same(err, nil)
        assert.are.same(result, {})
        done()
      end)
    end)
  end)

  async_it("auto error", function(done)
    Callback.auto({
      task1 = function(callback)
        callback("testerror")
      end,
      task2 = {
        "task1",
        function()
          error("task2 should not be called")
        end,
      },
      task3 = function(callback)
        callback("testerror2")
      end,
    }, function(err)
      assert.are.equal(err, "testerror")
      done()
    end)
  end)

  it("auto canceled", function(done)
    local call_order = {}
    Callback.auto({
      task1 = function(callback)
        table.insert(call_order, 1)
        callback(false)
      end,
      task2 = {
        "task1",
        function()
          table.insert(call_order, 2)
          error("task2 should not be called")
        end,
      },
      task3 = function(callback)
        table.insert(call_order, 3)
        callback("testerror2")
      end,
    }, function()
      assert.True(false, "should not get here")
      assert.are.same(call_order, { 1, 3 })
    end)
  end)

  it("does not start other tasks when it has been canceled", function(done)
    local call_order = {}
    Callback.auto({
      task1 = function(callback)
        table.insert(call_order, 1)
        --  defer calling task2, so task3 has time to stop execution
        Timers.set_timeout(callback)
      end,
      task2 = {
        "task1",
        function()
          table.insert(call_order, 2)
          assert.True(false, "task2 should not be called!")
        end,
      },
      task3 = function(callback)
        table.insert(call_order, 3)
        callback(false)
      end,
      task4 = {
        "task3",
        function()
          table.insert(call_order, 4)
          assert.True(false, "task4 should not be called")
        end,
      },
    }, function()
      assert.True(false, "should not get here")
      assert.are.same(call_order, { 1, 3 })
    end)
  end)

  it("auto no callback works", function()
    Callback.auto({
      task1 = function(callback)
        callback()
      end,
      task2 = {
        "task1",
        function(_, callback)
          callback()
        end,
      },
    })
  end)

  it("auto with concurrency no callback works", function()
    Callback.auto({
      task1 = function(callback)
        callback()
      end,
      task2 = {
        "task1",
        function(_, callback)
          callback()
        end,
      },
    }, 1)
  end)

  async_it("auto error should pass partial results", function()
    Callback.auto({
      task1 = function(callback)
        callback(nil, "result1")
      end,
      task2 = {
        "task1",
        function(_, callback)
          callback("testerror", "result2")
        end,
      },
      task3 = {
        "task2",
        function()
          assert.True(false, "task3 should not be called")
        end,
      },
    }, function(err, results)
      assert.are.equal(err, "testerror")
      assert.are.equal(results.task1, "result1")
      assert.are.equal(results.task2, "result2")
      done()
    end)
  end)

  -- Issue 24 on github: https://github.com/caolan/async/issues#issue/24
  -- Issue 76 on github: https://github.com/caolan/async/issues#issue/76
  it("auto removeListener has side effect on loop iteratee", function()
    Callback.auto({
      task1 = { "task3", function() end },
      task2 = {
        "task3",
        function()
          -- by design: DON'T call callback
        end,
      },
      task3 = function(callback)
        callback()
      end,
    })
  end)

  -- Issue 410 on github: https://github.com/caolan/async/issues/410
  it("auto calls callback multiple times", function()
    local final_call_count = 0
    pcall(function()
      Callback.auto(
        {
          task1 = function(callback)
            callback(null)
          end,
          task2 = {
            "task1",
            function(results, callback)
              callback(null)
            end,
          },
        },

        -- Error throwing final callback. This should only run once
        function()
          final_call_count = final_call_count + 1
          error("An error")
        end
      )
    end)

    Timers.set_timeout(function()
      assert.are.equal(final_call_count, 1)
    end, 10)
  end)

  async_it("auto calls callback multiple times with parallel functions", function()
    Callback.auto(
      {
        task1 = function(callback)
          Timers.set_timeout(function()
            callback("err")
          end, 0)
        end,
        task2 = function(callback)
          Timers.set_timeout(function()
            callback("err")
          end, 0)
        end,
      },
      -- Error throwing final callback. This should only run once
      function(err)
        assert.are.equal(err, "err")
        done()
      end
    )
  end)

  -- Issue 462 on github: https://github.com/caolan/async/issues/462
  async_it("auto modifying results causes final callback to run early", function()
    Callback.auto({
      task1 = function(callback)
        callback(nil, "task1")
      end,
      task2 = {
        "task1",
        function(results, callback)
          results.inserted = true
          Timers.set_timeout(function()
            callback(nil, "task2")
          end, 50)
        end,
      },
      task3 = function(callback)
        Timers.set_timeout(function()
          callback(nil, "task3")
        end, 100)
      end,
    }, function(_, results)
      assert.are.equal(results.inserted, true)
      assert.are.equal(results.task3, "task3")
      done()
    end)
  end)

  -- Issue 263 on github: https://github.com/caolan/async/issues/263
  it("auto prevent dead-locks due to inexistant dependencies", function()
    assert.has_error(function()
      return Callback.auto({
        task1 = {
          "noexist",
          function(results, callback)
            callback(null, "task1")
          end,
        },
      })
    end)
  end)

  -- Issue 263 on github: https://github.com/caolan/async/issues/263
  it("auto prevent dead-locks due to cyclic dependencies", function()
    assert.has_error(function()
      return Callback.auto({
        task1 = {
          "task2",
          function(results, callback)
            callback(null, "task1")
          end,
        },
        task2 = {
          "task1",
          function(results, callback)
            callback(null, "task2")
          end,
        },
      })
    end)
  end)

  -- Issue 1092 on github: https://github.com/caolan/async/issues/1092
  it("extended cycle detection", function()
    local task = function(name)
      return function(_, callback)
        callback(null, "task " + name)
      end
    end

    assert.has_error(function()
      return Callback.auto({
        a = { "c", task("a") },
        b = { "a", task("b") },
        c = { "b", task("c") },
      })
    end)
  end)

  -- Issue 988 on github: https://github.com/caolan/async/issues/988
  async_it("auto stops running tasks on error", function()
    Callback.auto(
      {
        task1 = function(callback)
          callback("error")
        end,
        task2 = function()
          assert.True(false, "test2 should not be called")
        end,
      },
      1,
      function(error)
        assert.are.equal(error, "error")
        done()
      end
    )
  end)

  async_it("ignores results after an error", function()
    Callback.auto({
      task1 = function(callback)
        Timers.set_timeout(function()
          callback("error")
        end, 25)
      end,
      task2 = function(cb)
        Timers.set_timeout(cb, 30)
      end,
      task3 = {
        "task2",
        function()
          assert.True(false, "task should not have been called")
        end,
      },
    }, function(err)
      assert.are.equal(err, "error")
      done()
    end)
  end)

  it("does not allow calling callbacks twice", function()
    assert.has_error(function()
      Callback.auto({
        bad = function(cb)
          cb()
          cb()
        end,
      }, function() end)
    end)
  end)

  it("should handle array tasks with just a function", function()
    Callback.auto({
      a = {
        function(cb)
          cb(nil, 1)
        end,
      },
      b = {
        "a",
        function(results, cb)
          assert.are.equal(results.a, 1)
          cb()
        end,
      },
    }, function() end)
  end)

  it("should avoid unncecessary deferrals", function()
    local is_sync = true

    Callback.auto({
      step1 = function(cb)
        cb(nil, 1)
      end,
      step2 = {
        "step1",
        function(results, cb)
          cb()
        end,
      },
    }, function()
      assert.are.equal(is_sync, true)
    end)

    is_sync = false
  end)

  -- it("should work on nil values correctly", function()
  --   return Callback.auto({
  --     -- name = "Izel",
  --     -- last_name = null,
  --     full_name = {
  --       -- "name",
  --       -- "last_name",
  --       function(callback)
  --         results = {}
  --         if results.last_name == null then
  --           return callback(nil, results.name)
  --         end
  --
  --         return callback(nil, "Izel")
  --         -- return callback(nil, results.name .. results.last_name)
  --       end,
  --     },
  --     other_details = {
  --       "full_name",
  --       function(_, callback)
  --         return callback()
  --       end,
  --     },
  --   }, function(_, result)
  --     assert.are.same(result, {
  --       -- name = "Izel",
  --       -- last_name = null,
  --       full_name = "Izel",
  --       other_details = null,
  --     })
  --
  --     null.something = 123 -- NOTE: This will throw error since null objects are immutable!
  --   end)
  -- end)
end)
