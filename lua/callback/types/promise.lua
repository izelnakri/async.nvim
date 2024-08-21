local Promise = {}

-- Create a new Promise
function Promise.new(executor)
  local promise = {
    _state = "pending", -- 'pending', 'fulfilled', 'rejected'
    _value = nil,
    _reason = nil,
    _thenCallbacks = {},
    _catchCallbacks = {},
    _finallyCallbacks = {},
  }

  -- Resolves the promise
  local function resolve(value)
    if promise._state ~= "pending" then
      return
    end
    promise._state = "fulfilled"
    promise._value = value
    for _, callback in ipairs(promise._thenCallbacks) do
      callback(value)
    end
    for _, callback in ipairs(promise._finallyCallbacks) do
      callback()
    end
  end

  -- Rejects the promise
  local function reject(reason)
    if promise._state ~= "pending" then
      return
    end
    promise._state = "rejected"
    promise._reason = reason
    for _, callback in ipairs(promise._catchCallbacks) do
      callback(reason)
    end
    for _, callback in ipairs(promise._finallyCallbacks) do
      callback()
    end
  end

  -- Run the executor function in a coroutine
  local co = coroutine.create(function()
    local success, err = pcall(executor, resolve, reject)
    if not success then
      reject(err)
    end
  end)
  coroutine.resume(co)

  -- :then method
  function promise:thenCall(onFulfilled)
    if self._state == "fulfilled" then
      onFulfilled(self._value)
    elseif self._state == "pending" then
      table.insert(self._thenCallbacks, onFulfilled)
    end
    return self
  end

  -- :catch method
  function promise:catch(onRejected)
    if self._state == "rejected" then
      onRejected(self._reason)
    elseif self._state == "pending" then
      table.insert(self._catchCallbacks, onRejected)
    end
    return self
  end

  -- :finally method
  function promise:finally(onFinally)
    if self._state ~= "pending" then
      onFinally()
    else
      table.insert(self._finallyCallbacks, onFinally)
    end
    return self
  end

  return promise -- NOTE: Maybe make it so it extends from coroutine instance: https://chatgpt.com/c/e2940cae-9a3f-473b-b739-f7446579eea0
end

-- Resolve a value into a promise
function Promise.resolve(value)
  return Promise.new(function(resolve)
    resolve(value)
  end)
end

-- Reject a value into a promise
function Promise.reject(reason)
  return Promise.new(function(_, reject)
    reject(reason)
  end)
end

-- Await a promise (for synchronous code)
function Promise.await(promise)
  local co = coroutine.create(function()
    local value
    local done = false

    promise
      :thenCall(function(result)
        value = result
        done = true
      end)
      :catch(function(err)
        value = err
        done = true
      end)

    while not done do
      coroutine.yield()
    end

    return value
  end)

  local success, result = coroutine.resume(co)
  return result
end

-- Create a promise with external resolvers
function Promise.withResolvers()
  local resolve, reject
  local promise = Promise.new(function(res, rej)
    resolve = res
    reject = rej
  end)

  return promise, resolve, reject
end

return Promise

-- :thenCall, :catch, :finally

-- promise-async creates a async queue, I might also need that/good to have for RSVP/render waiters maybe, its like supervision chain
-- tostring values maybe
-- Promise.all, Promise.all_settled, Promise.try(?), Promise.race, Promise.withResolvers()
