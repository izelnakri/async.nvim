local function defer(Promise, fn)
  vim.schedule(function()
    local success, err = pcall(fn)
    if not success then
      -- If the deferred function fails, raise the error to the main thread
      if type(Promise._unhandledRejectionHandler) == "function" then
        Promise._unhandledRejectionHandler(err)
      else
        vim.print(err)
      end
    end
  end)
end

local function is_callable(callback)
  if type(callback) == "function" then
    return true
  end

  local mt = getmetatable(callback)
  return mt and mt.__call ~= nil
end

local function adopt_promise_state(promise, x, resolve, reject)
  if x == promise then
    return reject("TypeError: Promise resolved with itself")
  end

  if x and (type(x) == "table" or is_callable(x)) then
    local success, thenCall
    success, thenCall = pcall(function()
      return x.thenCall
    end)

    if success and is_callable(thenCall) then
      local called = false

      local function resolve_once(y)
        if called then
          return
        end
        called = true
        adopt_promise_state(promise, y, resolve, reject)
      end

      local function reject_once(r)
        if called then
          return
        end
        called = true
        reject(r)
      end

      local success_inner, err = pcall(function()
        thenCall(x, resolve_once, reject_once)
      end)

      if not success_inner then
        reject_once(err)
      end
    else
      if success then
        resolve(x)
      else
        reject(thenCall)
      end
    end
  else
    resolve(x)
  end
end

return function(Promise, executor)
  if executor == nil then
    error("TypeError: Promise resolver is not a function")
  end

  local promise = {
    _state = "pending", -- 'pending', 'fulfilled', 'rejected'
    _value = nil,
    _reason = nil,
    _thenCallbacks = {},
    _finallyCallbacks = {},
    _triggerUnhandledRejection = function(self, reason)
      if not self._caught then
        if type(Promise._unhandledRejectionHandler) == "function" then
          Promise._unhandledRejectionHandler(reason)
        else
          vim.print(reason)
        end
      end
    end,
  }

  local function transition_to_state(newState, result)
    if promise._state ~= "pending" then
      return
    end

    promise._state = newState

    if newState == "fulfilled" then
      promise._value = result
      for _, callbackPair in ipairs(promise._thenCallbacks) do
        if callbackPair[1] then
          defer(Promise, function()
            callbackPair[1](result)
          end)
        end
      end
    elseif newState == "rejected" then
      promise._reason = result
      for _, callbackPair in ipairs(promise._thenCallbacks) do
        if callbackPair[2] then
          defer(Promise, function()
            callbackPair[2](result)
          end)
        end
      end
    end

    for _, callback in ipairs(promise._finallyCallbacks) do
      defer(Promise, callback)
    end

    -- Clear callbacks after execution
    promise._thenCallbacks = nil
    promise._finallyCallbacks = nil
  end

  local function resolve(value)
    if promise._state ~= "pending" then
      return
    end

    adopt_promise_state(promise, value, function(v)
      defer(Promise, function()
        transition_to_state("fulfilled", v)
      end)
    end, function(r)
      defer(Promise, function()
        transition_to_state("rejected", r)
      end)
    end)
  end

  local function reject(reason)
    if promise._state ~= "pending" then
      return
    end

    defer(Promise, function()
      transition_to_state("rejected", reason)
      promise:_triggerUnhandledRejection(reason)
    end)
  end

  local co = coroutine.create(function()
    local success, err = pcall(executor, resolve, reject)
    if not success then
      reject(err)
    end
  end)
  coroutine.resume(co)

  function promise:thenCall(onFulfilled, onRejected)
    self._caught = true
    local nextPromise
    nextPromise = Promise:new(function(resolve, reject)
      local function handleCallback(callback, value, resolve, reject)
        defer(Promise, function()
          if is_callable(callback) then
            local success, result = pcall(callback, value)
            if success then
              adopt_promise_state(nextPromise, result, resolve, reject)
            else
              reject(result)
            end
          else
            if self._state == "fulfilled" then
              resolve(value)
            else
              reject(value)
            end
          end
        end)
      end

      if self._state == "fulfilled" then
        handleCallback(onFulfilled, self._value, resolve, reject)
      elseif self._state == "rejected" then
        handleCallback(onRejected, self._reason, resolve, reject)
      elseif self._state == "pending" then
        table.insert(self._thenCallbacks, {
          function(value)
            handleCallback(onFulfilled, value, resolve, reject)
          end,
          function(reason)
            handleCallback(onRejected, reason, resolve, reject)
          end,
        })
      end
    end)

    return nextPromise
  end

  function promise:catch(onRejected)
    self._caught = true

    return self:thenCall(nil, onRejected)
  end

  function promise:finally(onFinally)
    if self._state ~= "pending" then
      defer(Promise, onFinally)
    else
      table.insert(self._finallyCallbacks, onFinally)
    end
    return self
  end

  return promise
end
