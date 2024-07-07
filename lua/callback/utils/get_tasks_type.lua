local function get_tasks_type(tasks)
  if vim.isarray(tasks) then
    return "list"
  end

  local tasks_type = type(tasks)
  if tasks_type == "table" then
    return "object"
  elseif tasks_type == nil then
    return nil
  end

  local metatable = getmetatable(tasks)

  return metatable and get_tasks_type(metatable)
end

return get_tasks_type
