local function detectCircularDependency(taskName, currentPath, inputs, pathHistory)
  if pathHistory[taskName] then
    error("Circular dependency detected")
  end

  pathHistory[taskName] = true

  local task = inputs[taskName]
  if not task then
    return
  end

  if type(task) == "table" then
    for i = 1, #task - 1 do
      detectCircularDependency(task[i], currentPath, inputs, pathHistory)
    end
  end

  pathHistory[taskName] = nil
end

return function(inputs)
  local Promise = require("promise")
  return Promise:new(function(resolve, reject)
    local results = {}
    local pending = {}
    local pathHistory = {}

    local function processTask(taskName)
      if results[taskName] then
        return Promise.resolve(results[taskName])
      end

      if pending[taskName] then
        return pending[taskName]
      end

      local task = inputs[taskName]
      if not task then
        return Promise.reject("Task '" .. taskName .. "' not found")
      end

      -- Check for circular dependencies
      detectCircularDependency(taskName, {}, inputs, pathHistory)

      local taskFn
      local taskDependencies = {}

      if type(task) == "table" then
        taskFn = task[#task]
        taskDependencies = { unpack(task, 1, #task - 1) }
      elseif type(task) == "function" then
        taskFn = task
      else
        return Promise.reject("Invalid task format for '" .. taskName .. "'")
      end

      -- If no dependencies, run the task immediately
      if #taskDependencies == 0 then
        local promise = Promise.resolve():and_then(taskFn):and_then(function(result)
          results[taskName] = result
          return result
        end)

        pending[taskName] = promise
        return promise
      end

      -- Resolve dependencies first
      local dependencyPromises = {}
      for _, dep in ipairs(taskDependencies) do
        if not inputs[dep] then
          return Promise.reject("Task '" .. dep .. "' not found")
        end

        table.insert(dependencyPromises, processTask(dep))
      end

      -- Run task after all dependencies are resolved
      local promise = Promise.all(dependencyPromises)
        :and_then(function(depResults)
          return taskFn(unpack(depResults))
        end)
        :and_then(function(result)
          results[taskName] = result
          return result
        end)

      pending[taskName] = promise
      return promise
    end

    -- Start processing all tasks
    local allPromises = {}
    for taskName, _ in pairs(inputs) do
      table.insert(allPromises, processTask(taskName))
    end

    -- Wait for all tasks to complete
    Promise.all(allPromises)
      :and_then(function()
        resolve(results)
      end)
      :catch(function(err)
        reject(err)
      end)
  end)
end
