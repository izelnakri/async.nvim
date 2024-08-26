## Async.nvim - "async" npm library port & Promises for lua in NeoVim!

To my knowledge this is the only plugin in the world that provides a fully working Promise implementation 
for lua in Neovim environment that doesnt cause C-Call boundary runtime errors. It is fully compliant with JS Promise 
spec and it passes the entire Promise A+ test suite:

```lua
local Promise = require("promise")

local promise = Promise:new(function(resolve, reject)
  resolve("some result")
end):thenCall(function(result)
  vim.print("this gets called with some result: " .. result)
end):catch(function(err)
  vim.print("no error here, this doesnt get called")
end)

-- or from outside the executor:
local promise, resolve, reject = Promise.with_resolvers()

local results = Promise.await(Promise.all({ promise1, promise2 }))
```

Async.nvim also provides methods to deal with callback based, higher-order asynchronous or synchronous functions in Neovim. 
It also provides ways to early return computations when needed or when certain cancellation cases provided. Additionally 
it allows developers to be selective on how or which error(s) should be used in a program in more maintanable manner.
This package is particularly useful when dealing with lua in neovim, either when configuring your neovim environment 
or building neovim plugins.

In other words, Callback.nvim is a very useful and powerful utility library to handle asynchronous functions where 
the asynchronous operation isn't wrapped in an asynchronous data structure like `Promise`, and where functions need to 
be controlled when they could be run asynchronously.

This library is inspired by the [async](https://www.npmjs.com/package/async) npm library, however it is more minimal 
and the api adjusted for lua specific conventions/differences compared to JavaScript. The test suite is initially ported 
from [async](https://www.npmjs.com/package/async) library, then I've enhanced it based on the needed adjustments or 
found missing cases. The core algorithm is ported from async npm library, it is imperative but it is very optimized, 
correct and memory efficient, handles edge cases like stack overflow on large collections well.

## Installation

**Lua**

```lua
-- using lazy.nvim
{
  'izelnakri/async.nvim',
  config = function()
    -- If you want to expose it globally:
    Callback = require("callback")
    Promise = require("promise")
    Timers = require("timers")

    -- or a dummy usage example:
    Callback.map({ '/home', '/usr' }, vim.uv.fs_stat, function(err, result) 
      vim.print(vim.inspect(result)) 
    end)

    -- promise example
    local something = Promise:new(function(resolve, reject)
      resolve({ last_name = "Nakri" })
    end):thenCall(function(result)
      vim.print("last_name should be: " .. result.last_name)
    end)
  end
}
```

## All Callback methods provided by this library:

- `Callback.all`
- `Callback.all_settled`
- `Callback.any`
- `Callback.any_limit`
- `Callback.any_series`
- `Callback.apply`
- `Callback.auto`
- `Callback.build(syncFunc) -> syncFuncWithCallback`
- `Callback.build_task(syncFunc, ...)`
- `Callback.each`
- `Callback.each_limit`
- `Callback.each_series`
- `Callback.filter`
- `Callback.filter_limit`
- `Callback.filter_series`
- `Callback.forever`
- `Callback.hash` - not implemented yet, like `Callback.all` but can *only* receives an object of values and/or tasks
- `Callback.hash_settled` - not implemented yet, like `Callback.all_settled` but can *only* receives an object of values and/or tasks
- `Callback.log`
- `Callback.map`
- `Callback.map_limit`
- `Callback.map_series`
- `Callback.parallel` - Exclusively runs tasks
- `Callback.parallel_limit` - Exclusively runs tasks with concurrency limit
- `Callback.parallel_limit_settled` - not implemented yet, waits all tasks to finish
- `Callback.parallel_settled` - not implemented yet, waits all tasks to finish
- `Callback.race`
- `Callback.reduce`
- `Callback.reduce_right`
- `Callback.resolve`
- `Callback.run`
- `Callback.series` - Exclusively runs tasks
- `Callback.series_settled` - not implemented yet, exclusively runs tasks, waits all tasks to finish
- `Callback.times`
- `Callback.times_limit`
- `Callback.times_series`
- `Callback.try_each`
- `Callback.waterfall`

## Primitive types

- **callback**: `function(err, result) end | function(...params, err, result) end`
- **task**: `function(callback) end | function(...params, callback) end`
- **iterator**: `function(value: any, callback: callback, index: number, collection: any[]) end`
- **task_operation_list**: `{ "keyOne", "keyTwo", function() end }` => A list: always ends with a function(last task).

## Async Control methods:

Async control methods mean first argument expects a list or object of async functions to *run*. Normal Callback methods
expect list or object of values while async control methods expect list or object of async functions to *execute* 
without iteratee function as 2nd argument.

- `Callback.waterfall` -> runs `Callback.each_series` on the provided async function tasks
- `Callback.parallel` -> runs `Callback.map` on the provided async function tasks
- `Callback.series` -> runs `Callback.map_series` on the provided async function tasks
- `Callback.race` -> runs all tasks passes the first task that calls its callback
- `Callback.try_each` -> runs all tasks passes the first successful task that calls its callback, thus **errors dont early return**
- `Callback.forever` -> runs all tasks passes recursively until an error or result provided in the tasks callback


In the docs when you see "Errors may early return", it means errors can stop the task iteration, however no function actually gets suspended.

Callback module methods logical equivalents in the JS Promise standard library are:

- [Promise.all](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all) => `Callback.all`
- [Promise.allSettled](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/allSettled) => `Callback.all_settled`
- [Promise.any](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/any) => `Callback.any`
- [Promise.race](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/race) => `Callback.race`
- [Promise.reject](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/reject) => `callback(result)`
- [Promise.resolve](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/resolve) => `callback(nil, value)`
- [Promise.withResolvers](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/resolve) => `function(err, callback) return callback(err, result) end`

## Null type

In Lua `nil` value ommits/removes the key value pair from a table(as in list and object). This makes the list length
and objects behave unpredictably compared to most other programming languages. In order to eliminate this confusion
and make lists lengths predictable, this library exposes a `null` immutable object that you can exports to check against
your tests:

```lua
local null = require("callback.types.null")

Callback.map({ 'a', 'b', 'c' }, function(element)
  return callback()
end, function(err, results)
  assert.are.same(results, { null, null, null }) -- NOTE: Here we use null objects instead of nil
end)

-- NOTE: This API doesn't exist yet, it will be an extension/superset of Callback.auto API:
Callback.hash({
  name = "Izel",
  last_name = nil,
  full_name = { "name", "last_name", function(results, callback)
    if (results.last_name == null) then
      return callback(nil, results.name)
    end

    return callback(nil, results.name .. results.last_name)
  end},
  other_details = { "full_name", function(results, callback)
    return callback()
  end}
}, function(err, result)
  assert.are.same(result, {
    name = "Izel",
    last_name = null,
    full_name = "Izel",
    other_details = null
  })

  type(null) == "table"
  null.something = 123 -- NOTE: This will throw error since null objects are immutable!
end)

```

- What if I want iterator functions(each, filter, map, reduce, times to wait for *all* errors to run(?))

## Future notes:

On _settled calls, error value is always a list with null objects(or error results)
Sanitize errors so they can be nil or null

Coming soon: `Callback.hash`, `Callback.hash_settled` APIs & Promise API/return 
functionality. `_settled` waits for all tasks to settle before running result callback. These methods are different 
from all other methods such that they can receive *any* values in lua, instead of just tasks, or task_operation_lists:
`all`, `all_settled`, `hash`, `hash_settles` is a higher level API than other `Callback` methods because of this.
Waiting for all tasks to settle doesnt exist right now, `all_settled` will have it with *any* value provided.
If I want to make tasks operation wait for all the settlement of *all* provided tasks, I have to use the higher-level
`Callback.all_settled` or `Callback.hash_settled` methods/API. OperationOptions type with concurrency: x, timeout: y, signal: z, onEvent, retry: a

Today `Callback.queue` and `Callback.cargo` functions are NOT implemented. 

Cargo: passes array of tasks to a worker at once, could optionally repeat when the worker is finished.
CargoQueue: runs queue concurrently on workers in parallel.
Queue: passes one task at a time to a single worker.

These functions provide no persistence(for process restarts/kills) and their behavior might be achieved without needimg 
them, resorting to existing methods here with a distributed store like RabbitMQ or PostgreSQL(when set up clustered).

Promise(function(resolve, reject)) -> **reject function could also be a callback shaped?**, whereas reject(nil) calls resolve and reject(false) cancelles and reject(nil, smt) resolves smt?
resolve function could be a curry of `function(val) return callback(nil, val) end`
