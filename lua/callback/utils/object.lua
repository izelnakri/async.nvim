local Object = {}

---Returns an iterator of all own property names of the given object.
---@param object table: The object to get keys from
---@return Iter: Iterator function
function Object.keys(object)
  return vim.iter(object):map(function(key)
    return key
  end)
end

function compare(a, b)
  return a < b
end

---Returns an iterator of all own property names sorted of the given object.
---@param object table: The object to get sorted keys from
---@return Iter: Iterator function
function Object.sorted_keys(object)
  local result = {}
  for key in pairs(object) do
    table.insert(result, key)
  end

  table.sort(result)

  return vim.iter(result)
end

---Returns an iterator of all own property values of the given object.
---@param object table: The object to get values from
---@return Iter: Iterator function
function Object.values(object)
  return vim.iter(object):map(function(_, value)
    return value
  end)
end

return Object
