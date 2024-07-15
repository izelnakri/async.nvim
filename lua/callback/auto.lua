local null = require("callback.types.null")
local Object = require("callback.utils.object")
local List = require("callback.utils.list")
local once = require("callback.internal.once")
local only_once = require("callback.internal.only_once")

---Most advanced low-level async control operation that receives an object of tasks where values could be task or order of tasks dependening/referencing other keys/tasks in the object.
---@param tasks table<string, function> Collection of tasks or order of tasks to pass as a result to result_callback. When tasks callback passes nil as result, the result gets converted to immutable & empty null objects to keep the table length intact in lua.
---@param concurrency number The maximum number of tasks at a time to run in parallel.
---@param final_callback? fun(err: any, result: any[]) Result callback runs when all tasks run their callback  or **when one task runs callback with error**. **Can be skipped upon cancellation**
---@return any callback This will be changed to a Promise-like abstraction in the future
return function(tasks, concurrency, final_callback)
  if type(concurrency) ~= "number" then
    final_callback = concurrency
    concurrency = nil
  end

  final_callback = once(final_callback or function() end) -- NOTE: This is essential for calling result callback once!

  local task_count = #(Object.keys(tasks):totable())
  if task_count == 0 then
    return final_callback(nil, {})
  elseif not concurrency then
    concurrency = task_count
  end

  local results = {}
  local running_tasks = 0
  local canceled = false
  local has_error = false

  local listeners = {}
  local ready_tasks = {}

  -- NOTE: For cycle detection
  local ready_to_check = {} -- tasks that have been identified as reachable
  -- without the possibility of returning to an ancestor task
  local unchecked_dependencies = {}

  local process_queue = function()
    if canceled then
      return
    elseif (#ready_tasks == 0) and (running_tasks == 0) then
      return final_callback(nil, results)
    end

    while (#ready_tasks > 0) and (running_tasks < concurrency) do
      List.shift(ready_tasks)()
    end
  end

  local task_complete = function(task_name)
    local task_listeners = listeners[task_name] or {}
    List.each(task_listeners, function(fn)
      return fn()
    end)
    process_queue()
  end

  local run_task = function(key, task)
    if has_error then
      return
    end

    local task_callback = only_once(function(err, ...)
      local result = { ... }

      running_tasks = running_tasks - 1

      if err == false then
        canceled = true
        return
      elseif #result < 2 then
        result = (result[1] == nil and null) or result[1]
      end

      if err then
        local safe_results = {}
        Object.keys(results):each(function(r_key)
          safe_results[r_key] = results[r_key]
        end)
        safe_results[key] = (result == nil and null) or result

        has_error = true
        listeners = {}

        if canceled then
          return
        end

        final_callback(err, safe_results)
      else
        results[key] = (result == nil and null) or result
        task_complete(key)
      end
    end)

    running_tasks = running_tasks + 1
    local task_fn = task[#task]

    if #task > 1 then
      task_fn(results, task_callback)
    else
      task_fn(task_callback)
    end
  end

  local enqueue_task = function(key, task)
    table.insert(ready_tasks, function()
      return run_task(key, task)
    end)
  end

  local add_listener = function(task_name, fn)
    local task_listeners = listeners[task_name]
    if not task_listeners then
      listeners[task_name] = {}
      task_listeners = listeners[task_name]
    end

    table.insert(task_listeners, fn)
  end

  local get_dependents = function(task_name)
    local result = {}
    Object.keys(tasks):each(function(key)
      local task = tasks[key]
      if vim.isarray(task) and List.index_of(task, task_name) then
        table.insert(result, key)
      end
    end)

    return result
  end

  local check_for_deadlocks = function()
    -- Kahn's algorithm
    -- https://en.wikipedia.org/wiki/Topological_sorting#Kahn.27s_algorithm
    -- http://connalle.blogspot.com/2013/10/topological-sortingkahn-algorithm.html
    local current_task
    local counter = 0

    while #ready_to_check > 0 do
      current_task = List.pop(ready_to_check)
      counter = counter + 1
      List.each(get_dependents(current_task), function(dependent)
        unchecked_dependencies[dependent] = unchecked_dependencies[dependent] - 1
        if unchecked_dependencies[dependent] == 0 then
          List.push(ready_to_check, dependent)
        end
      end)
    end

    if counter ~= task_count then
      return error("Callback.auto cannot execute tasks due to a recursive dependency")
    end
  end

  Object.sorted_keys(tasks):each(function(key)
    local task = tasks[key]

    if not vim.isarray(task) then
      -- no dependencies
      enqueue_task(key, { task })
      table.insert(ready_to_check, key)
      return
    end

    local dependencies = List.slice(task, 0, #task - 1)
    local remaining_dependencies = #dependencies
    if remaining_dependencies == 0 then
      enqueue_task(key, task)
      table.insert(ready_to_check, key)
      return
    end

    unchecked_dependencies[key] = remaining_dependencies

    List.each(dependencies, function(dependency_name)
      if not tasks[dependency_name] then
        return error(
          "Callbackj.auto task '"
            .. key
            .. "' has a non-existent dependency '"
            .. vim.inspect(dependency_name)
            .. "' in '"
            .. vim.inspect(dependencies)
        )
      end

      add_listener(dependency_name, function()
        remaining_dependencies = remaining_dependencies - 1
        if remaining_dependencies == 0 then
          enqueue_task(key, task)
        end
      end)
    end)
  end)

  check_for_deadlocks()
  process_queue()

  return final_callback -- NOTE: in async npm it is return callback[PROMISE_SYMBOL]
end
