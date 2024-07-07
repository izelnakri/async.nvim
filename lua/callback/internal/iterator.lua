-- TODO: Maybe i can accomplish these with pairs() instead of custom iterators, these just make next() available

local Object = {}

function Object.keys(object)
  local result = {}
  for key in vim.spairs(object) do
    table.insert(result, key)
  end

  return result
end

function Object.is_object(value)
  return (type(value) == "table" or type(getmetatable(value)) == "table") and (not vim.isarray(value))
end

local create_list_iterator = function(list)
  local i = 0
  local length = #list

  return function() -- next function
    i = i + 1
    if i < length + 1 then
      return { left = i, right = list[i] }
    end
  end
end

local create_object_iterator = function(object)
  -- NOTE: Object.key order has to be correct
  local keys = (object and Object.keys(object)) or {}
  local i = 0
  local length = #keys
  return function() -- next function
    i = i + 1
    local key = keys[i]
    -- NOTE: handle skipped keys if they get added:
    -- if key == "__proto__" then
    --   return next()
    -- end

    if i < length + 1 then
      return { left = key, right = object[key] }
    end
  end
end

-- TODO: Maybe this is redundant with pairs() function
return function(collection)
  if Object.is_object(collection) then
    return create_object_iterator(collection)
  else
    return create_list_iterator(collection)
  end
end

-- function createES2015Iterator(iterator) {
--     var i = -1;
--     return function next() {
--         var item = iterator.next();
--         if (item.done)
--             return null;
--         i++;
--         return {value: item.value, key: i};
--     }
-- }
--
-- export default function createIterator(coll) {
--     if (isArrayLike(coll)) {
--         return createArrayIterator(coll);
--     }
--
--     var iterator = getIterator(coll);
--     return iterator ? createES2015Iterator(iterator) : createObjectIterator(coll);
-- }
