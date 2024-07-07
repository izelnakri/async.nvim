return function(fn)
  local called = false

  return function(...)
    if fn == nil or called == true then
      return
    end
    called = true
    return fn(...)
  end
end
