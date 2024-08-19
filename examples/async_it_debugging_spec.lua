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
    local ok, err = pcall(coroutine.resume, target_coroutine.co) -- TODO: It should be here
    log("finalize_coroutine", ok, err)
    -- if not ok or optional_error ~= nil then
    --   vim.print("ZZZZZZ NOT OK CALLLLL")
    --   vim.print(err) -- NOTE: is this needed?
    -- end

    flush_stdout()
    target_coroutine.done_callback(optional_error)
  end
end

_G.done = function(optional_error) -- could have done_callback passed as param, probably not a good idea
  coroutine_index = coroutine_index + 1
  if coroutine_index > #coroutine_queue then
    return error("You are calling done() on a test but it gets called more than async_it tests")
  end

  finalize_coroutine(coroutine_queue[coroutine_index], optional_error)
end

local async = function(func, done_callback, ...)
  local args = { ... }
  local co = coroutine.create(function()
    vim.print("YIELD :" .. #coroutine_queue)
    local ok, err = pcall(func, unpack(args))
    log("func", ok, err)

    flush_stdout() -- Ensure stdout is flushed

    vim.print("BEFORE YIELD :" .. #coroutine_queue)
    coroutine.yield()
    vim.print("AFTER YIELD")

    -- done_callback() -- Signal completion when the function is done
  end)

  table.insert(coroutine_queue, { co = co, done_callback = done_callback })

  local ok, err = pcall(coroutine.resume, co)
  log("coroutine.initial_call", ok, err)

  if not ok then
    vim.print("NOT OK CALLLLL")
    coroutine_index = coroutine_index + 1
    finalize_coroutine(coroutine_queue[coroutine_index])
    flush_stdout()
    return error(err)
  end

  flush_stdout() -- Ensure stdout is flushed before yielding
end

local index = 0
local async_it = function(title, func)
  index = index + 1
  local local_index = index
  local found_error
  return it(title, function(...)
    local is_done = false -- Local to each async_it run

    local function done_callback(err)
      if err ~= nil then
        found_error = err
      end

      is_done = true
    end

    async(func, done_callback, ...)
    -- log("async_it.async", ok, result)
    -- if not ok then
    --   vim.print("NOT OK CALL")
    --   done_callback(result) -- NOTE: maybe remove this
    -- end

    while not is_done do -- TODO: make it so it can listen to thrown function inside the event loop
      vim.print("still not done?:" .. local_index)
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
      assert.are.equal(true, false) -- NOTE: Changing this to false doesnt work
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
      assert.are.equal("A", "B")

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

      assert.are.equal("2AA", "2AB")

      done() -- Calls done_callback to unblock the async_it
    end)

    vim.print("cool")

    assert.are.equal("AA", "AB")
  end)

  -- TODO: This one is problematic, current implementation cannot catch *all* event loop exceptions properly
  it("with defer function works", function()
    vim.uv.fs_statfs("./stylua.toml", function(err, res)
      assert.are.equal(true, false)
      done()
    end)

    vim.wait(6000)
  end)

  -- -- TODO: This cant be obtained neither
  -- async_it("with defer function works", function()
  --   vim.defer_fn(function()
  --     print("zXXX")
  --     assert.are.equal("A", "B")
  --
  --     done() -- Calls done_callback to unblock the async_it
  --   end, 1000)
  --   print("zAAAAAAAA")
  --
  --   assert.are.equal("A", "A")
  -- end)
end)
