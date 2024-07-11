---@param sync_func fun(...) Makes a synchronous function asynchronous without calling it, optionally applies parameters
---@return fun(..., callback: fun) Returns a callback shaped asynchronous function. In future also returns promise
return function(sync_func, ...)
  local provided_arguments = { ... }

  return function(...)
    local arguments_on_call = { ... }
    local callback = table.remove(arguments_on_call) -- NOTE: just delete it

    for _, value in pairs(provided_arguments) do
      arguments_on_call[#arguments_on_call + 1] = value
    end
    vim.print("arguments_on_call is:")
    vim.print(vim.inspect(arguments_on_call))

    local success, result_or_error = pcall(sync_func, unpack(arguments_on_call))

    if type(callback) == "function" then
      if success then
        callback(nil, result_or_error)
      else
        callback(result_or_error, nil)
      end
    end

    return {} -- NOTE: In future return promise
  end
end
