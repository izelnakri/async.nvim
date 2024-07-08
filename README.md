## Callback.nvim - "async" npm library port for lua

Callback.nvim provides methods to deal with callback based, higher-order asynchronous or synchronous functions. It also
provides ways to early return computations when occured or when certain cancellation cases provided. Additionally allows
being selective on how or which error(s) should be used in a program. This is particularly useful when dealing with lua
in neovim, either when configuring your neovim environment or building neovim plugins.

In other words, Callback.nvim is a utility library to handle asynchronous functions where the asynchronous operation
isn't wrapped in an asynchronous data structure like `Promise` or `Future`, and where functions need to be controlled
when they could be run asynchronously.

This library is inspired by the [async](https://www.npmjs.com/package/async) npm library, however it is more minimal 
and the api adjusted for lua specific conventions/differences compared to JavaScript. The test suite is initially ported 
from [async](https://www.npmjs.com/package/async) library, then I've enhanced it based on the needed adjustments or 
found missing cases. The core algorithm is ported from async npm library, it is imperative but it is very optimized, 
correct and memory efficient, handles edge cases like stack overflow on large collections well.

In future I might build a JS Promise-like data structure so Callback methods can be awaited or aborted from outside or
composed with other Callback methods. This lua plugin is already very powerful & useful.

## Installation

**Lua**

```lua
-- using lazy.nvim
{
  'izelnakri/callback.nvim',
  config = function()
    -- If you want to expose it globally:
    Callback = require("callback")

    -- or a dummy usage example:
    Callback.map({ '/home', '/usr' }, vim.uv.fs_stat, function(err, result) 
      vim.print(vim.inspect(result)) 
    end)
  end
}
```

## All Callback methods provided by this library:

- `Callback.any`
- `Callback.any_limit`
- `Callback.any_series`
- `Callback.build_iteratee`
- `Callback.each`
- `Callback.each_limit`
- `Callback.each_series`
- `Callback.filter`
- `Callback.filter_limit`
- `Callback.filter_series`
- `Callback.forever`
- `Callback.map`
- `Callback.map_limit`
- `Callback.map_series`
- `Callback.parallel`
- `Callback.parallel_limit`
- `Callback.race`
- `Callback.reduce`
- `Callback.reduce_right`
- `Callback.series`
- `Callback.times`
- `Callback.times_limit`
- `Callback.times_series`
- `Callback.try_each`
- `Callback.waterfall`

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

If Callback module methods logical equivalents in the JS Promise standard library are:

- [Promise.all](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all) => `Callback.parallel`
- [Promise.allSettled](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/allSettled) => Doesnt exist, because parallel funcs early return on first error
- [Promise.any](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/any) => `Callback.any`
- [Promise.race](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/race) => `Callback.race`
- [Promise.reject](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/reject) => `callback(result)`
- [Promise.resolve](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/resolve) => `callback(nil, value)`
- [Promise.withResolvers](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/resolve) => `function(err, callback) return callback(err, result) end`
