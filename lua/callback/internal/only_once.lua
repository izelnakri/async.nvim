return function(fn)
  local called = false

  return function(...)
    if fn == nil or called == true then
      return error("callback() function should be called only once inside an iteratee!")
    end
    called = true
    return fn(...)
  end
end
