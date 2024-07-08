## Callback.nvim - "async" npm library port for lua

Callback.nvim provides methods to deal with callback based, higher-order asynchronous or synchronous functions. It also
provides ways to early return computations when occured or certain cancellation cases provided. Additionally allows
being selective how or which error(s) should be used in a program. This is particularly useful when dealing with lua
in neovim, either to configure your neovim environment or the build neovim plugins.

In other words, Callback.nvim is a utility library to handle asynchronous functions where the asynchronous operation
isn't wrapped in an asynchronous data structure like `Promise` or `Future`, and where functions need to be controlled
when they could be run asynchronously.

This library is inspired by the [async](https://www.npmjs.com/package/async) npm library, however it is more minimal 
and the api adjusted for lua specific conventions/differences compared to JavaScript. The test suite is initially ported 
from [async](https://www.npmjs.com/package/async) library, then I've enhanced it based on the needed adjustments or 
found missing cases. 

## Callback methods that can early return when not cancelled:

- `Callback.map`
- `Callback.map_series`
- `Callback.map_limit`
- `Callback.race`
- `Callback.series`
- `Callback.try_each`

## Callback methods that *DO NOT* early return on error:

- `Callback.each` - - Error object is the last error
- `Callback.each_series` - Error object is the last error. !! Check if this early returns on error, seems like its only Callback.series(which is parseq.fallback)
- `Callback.reduce` - Unless error provided on callback/next
- `Callback.waterfall` - Error object is the last error
- `Callback.parallel` - Eror object is the last error

## Async Control methods:

Async control methods mean first argument expects a list or object of async functions to *run*. Normal Callback methods
expect list or object of values while async control methods expect list or object of async functions to *execute* 
without iteratee function as 2nd argument.

- `Callback.waterfall` -> runs `Callback.each_series` on the provided async function tasks, **errors dont early return**
- `Callback.parallel` -> runs `Callback.series` on the provided async function tasks, **errors dont early return**
- `Callback.series` -> runs `Callback.map_series` on the provided async function tasks, thus **error can early return**
- `Callback.race` -> runs `Callback.map` on the provided async function tasks, thus **error can early return**


If Callback module was a JS Promise standard library module, their equivalent would be:

- [Promise.all](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all) => `Callback.parallel`
- [Promise.allSettled](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/allSettled) => Doesnt exist, because parallel funcs early return on first error
- [Promise.any](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/any) => `Callback.any`
- [Promise.race](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/race) => `Callback.race`
- [Promise.reject](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/reject) => `callback(result)`
- [Promise.resolve](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/resolve) => `callback(nil, value)`
- [Promise.withResolvers](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/resolve) => `function(err, callback) return callback(err, result) end`
