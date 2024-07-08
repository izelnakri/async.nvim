-- NOTE: This should return a promise object instead in future

return function(func)
  local callback = function(err, value)
    if err == false then
      return { value = value, err = err, cancel = true }
    elseif err then
      return { value = value, err = err, cancel = false }
    end

    return { value = value, err = nil, cancel = false }
  end

  return func(callback)
end

-- NOTE: Maybe implement reflect_all: maps list of funcs to reflect(func) inside
-- NOTE :Timeout shows it as { err, data } -> Should be { err, value, cancel } -> timeout message is inside err
-- Shape of a computation is:
-- { err: Err, func: func, value: any, cancel: boolean }
-- --> Maybe also pid?, also onSuccess: func[], onFail: func[], onCancel: func[]
-- --> would it have .await(), .abort(), .then(), .catch(), .resolve(), .reject(), & status
-- ::new() generates it
