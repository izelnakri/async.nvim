require("async.test")

local Promise = require("promise")

describe("Promise.build_task", function()
  async_it("passes initial and curried arguments correctly", function(done)
    local function example_promise_function(arg1, arg2, arg3)
      return Promise:new(function(resolve)
        resolve(arg1 .. arg2 .. arg3)
      end)
    end

    local task = Promise.build_task(example_promise_function, "Hello", " ")
    task("World")
      :thenCall(function(result)
        assert.are.equal("Hello World", result)
        done()
      end)
      :catch(function()
        vim.print("ZUUUUUUUUUUUU")
        error("build_task should not reject if arguments are passed correctly.")
      end)
  end)

  async_it("handles no initial arguments and multiple curried arguments", function(done)
    local function example_promise_function(arg1, arg2)
      return Promise:new(function(resolve)
        resolve(arg1 .. arg2)
      end)
    end

    local task = Promise.build_task(example_promise_function)
    task("Foo", "Bar")
      :thenCall(function(result)
        assert.are.equal("FooBar", result)
        done()
      end)
      :catch(function()
        error("build_task should not reject if all arguments are passed as curried.")
      end)
  end)

  async_it("returns the result of the promise-returning function", function(done)
    local function example_promise_function(arg)
      return Promise:new(function(resolve)
        resolve(arg .. " success")
      end)
    end

    local task = Promise.build_task(example_promise_function, "Task")
    task()
      :thenCall(function(result)
        assert.are.equal("Task success", result)
        done()
      end)
      :catch(function()
        error("build_task should resolve to the result of the promise.")
      end)
  end)

  async_it("raises an error if the function does not return a promise", function()
    local function non_promise_function(arg)
      return arg .. " not a promise"
    end

    local task = Promise.build_task(non_promise_function, "This")

    local success, error_message = pcall(task, "should fail")
    assert.is_false(success)
    assert.has.match("only accepts functions that return a promise", error_message)
    done()
  end)

  async_it("works with no initial arguments and no curried arguments", function(done)
    local function example_promise_function()
      return Promise:new(function(resolve)
        resolve("No arguments")
      end)
    end

    local task = Promise.build_task(example_promise_function)
    task()
      :thenCall(function(result)
        assert.are.equal("No arguments", result)
        done()
      end)
      :catch(function()
        error("build_task should resolve correctly even with no arguments.")
      end)
  end)

  async_it("works with multiple initial and curried arguments", function(done)
    local function example_promise_function(arg1, arg2, arg3, arg4)
      return Promise:new(function(resolve)
        resolve(arg1 .. arg2 .. arg3 .. arg4)
      end)
    end

    local task = Promise.build_task(example_promise_function, "Hello", ", ")
    task("world", "!")
      :thenCall(function(result)
        assert.are.equal("Hello, world!", result)
        done()
      end)
      :catch(function()
        error("build_task should correctly concatenate all initial and curried arguments.")
      end)
  end)
end)
