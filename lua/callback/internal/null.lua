obj = {}

null = setmetatable(obj, {
  __type = "null",
  __index = function(_self, key)
    return obj[key]
  end,

  __newindex = function()
    error("null table is frozen", 2)
  end,
})

return null -- NOTE: we represent nil returns as null in lua because in lua tables nil gets ommitted
