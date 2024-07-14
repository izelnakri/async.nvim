local List = {}

---Executes a provided function once for each list element.
---@param list table: The list to iterate
---@param callback function: A function that takes an element and its index
---@return table: The provided list, unchanged.
function List.each(list, callback)
  for index, value in ipairs(list) do -- NOTE: Should this be pairs instead of ipairs(?)
    callback(value, index)
  end

  return list
end

---Finds the first index of the given value in the list.
---@param list table: The list to search
---@param value any: The value to find
---@return number?: The index of the value, or nil if not found
function List.index_of(list, value)
  for index, list_value in pairs(list) do
    if list_value == value then
      return index
    end
  end
end

---Joins all elements of the list into a string.
---@param list table: The list to join
---@param separator string: The separator to use between elements (default is ",")
---@return string: A string with all list elements joined by the separator
function List.join(list, separator)
  return table.concat(list, separator or ",")
end

---Removes the last element from the list and returns it.
---@param list table: The list to modify
---@return any: The removed element
function List.pop(list)
  return table.remove(list)
end

---Adds one or more elements to the end of the list and return the length
---@param list table: The list to modify
---@param ... any: The elements to add
---@return number: The new length of the list
function List.push(list, ...)
  for _, value in pairs({ ... }) do
    table.insert(list, value)
  end

  return #list
end

---Removes the first element from the list and returns it.
---@param list table: The list to modify
---@return any: The removed element
function List.shift(list)
  return table.remove(list, 1)
end

---Returns a shallow copy of a portion of the list into a new list.
---@param list table: The list to slice
---@param start number: The start index (inclusive, default is 1)
---@param finish? number: The end index (inclusive, default is length of the list)
---@return table: A new list containing the sliced elements
function List.slice(list, start, finish)
  local result = {}

  for index = start or 1, finish or #list do
    table.insert(result, list[index])
  end

  return result
end

return List
