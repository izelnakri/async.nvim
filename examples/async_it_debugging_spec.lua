-- NOTE: This magic does shim vim.uv functions properly to be test safe:
-- Unfortunately, 'vim.uv' itself does not provide a built-in mechanism to globally intercept or handle errors in callbacks
local function wrap_all_uv_functions()
  for name, func in pairs(vim.uv) do
    if type(func) == "function" then
      vim.uv[name] = function(...)
        local args = { ... }
        local callback = args[#args]

        if type(callback) == "function" then
          args[#args] = function(err, ...)
            if err then
              done(err)
            else
              local ok, wrapped_err = pcall(callback, err, ...)
              if not ok then
                done(wrapped_err)
              end
            end
          end
        end

        return func(unpack(args))
      end
    end
  end

  -- Wrap vim.schedule to catch exceptions on test
  local original_schedule = vim.schedule
  vim.schedule = function(callback)
    original_schedule(function()
      local ok, err = pcall(callback)
      if not ok then
        done(err)
      end
    end)
  end
end

wrap_all_uv_functions() -- Call this function at the beginning of your test file or setup

local Callback = require("callback")
local Timers = require("callback.utils.timers")

local log = function(token, status, err)
  vim.print(token .. " ok is:")
  vim.print(status)
  vim.print(token .. " err is:")
  vim.print(err)
  vim.print("")
end

local coroutine_queue = {}
local coroutine_index = 0

local function flush_stdout()
  if io and io.flush then
    io.flush()
  end
end

local finalize_coroutine = function(target_coroutine, optional_error)
  local status = coroutine.status(target_coroutine.co)
  if status == "dead" then
    return true
  else
    coroutine.resume(target_coroutine.co) -- NOTE: Change from this below:

    target_coroutine.done_callback(optional_error)
  end
end

_G.done = function(optional_error) -- optional_error param essential for shimming vim.uv exception catching
  coroutine_index = coroutine_index + 1
  if coroutine_index > #coroutine_queue then
    return error("You are calling done() on a test but it gets called more than async_it tests")
  end

  finalize_coroutine(coroutine_queue[coroutine_index], optional_error)
end

local index = 0
local async_it = function(title, func)
  index = index + 1
  -- local local_index = index
  local found_error
  return it(title, function(...)
    local is_done = false -- Local to each async_it run

    local function done_callback(err)
      flush_stdout()

      if err ~= nil then
        found_error = err
      end

      is_done = true
    end

    local wrapped_func = function(...) -- Wrap the original function to catch errors
      local ok, err = pcall(func, ...)
      if not ok then
        done(err)
      end
    end

    local args = { ... }
    local co = coroutine.create(function()
      wrapped_func(unpack(args))

      coroutine.yield()
    end)

    table.insert(coroutine_queue, { co = co, done_callback = done_callback })
    coroutine.resume(co) -- NOTE: Changed from the thing below:

    if is_done and found_error then
      error(found_error)
    end

    while not is_done do
      -- vim.print("still not done?:" .. local_index)
      vim.wait(10) -- Small wait to prevent a busy loop
      if found_error then
        error(found_error)
      end
    end
  end)
end

describe("Callback.all", function()
  async_it("works with timeout", function()
    vim.print("RUNNIN SOMETHING")
    vim.print("")

    Timers.set_timeout(function()
      assert.are.equal(true, true) -- NOTE: Changing this to false doesnt work
      done()
    end, 1000)
  end)

  async_it("with no callbacks working", function()
    vim.print("XRUNNIN SOMETHING")
    vim.print("")
    assert.are.equal(true, true) -- NOTE: Change this to false
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
