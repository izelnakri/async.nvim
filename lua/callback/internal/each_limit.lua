local iterator = require("callback.internal.iterator")
local once = require("callback.internal.once")
local only_once = require("callback.internal.only_once")
local break_loop = require("callback.internal.break_loop")
local null = require("callback.internal.null")

return function(concurrency_limit, obj, iteratee, callback)
  callback = once(callback)

  if concurrency_limit <= 0 then
    return error("concurrencyLimit cannot be less than 1")
  end

  if not obj then
    return callback(nil, null) -- Early termination if there is no obj
  end

  local next_element = iterator(obj)
  local done = false
  local canceled = false
  local running = 0
  local looping = false
  local last_result
  local replenish

  local iteratee_callback = function(err, result)
    last_result = (result == nil and null) or result
    if canceled then
      return
    end
    running = running - 1
    if err then
      done = true
      callback(err)
    elseif err == false then -- NOTE: This is cancel case, never leads to result_callback
      done = true
      canceled = true
    elseif result == break_loop or (done and running <= 0) then -- NOTE: This short-circuiting, leads to result_callback
      done = true
      return callback(nil, last_result)
    elseif not looping then
      replenish()
    end
  end

  replenish = function()
    -- vim.print("replenish call")
    looping = true

    while running < concurrency_limit and not done do
      local elem = next_element()
      if elem == nil then
        done = true
        if running <= 0 then
          callback(nil, last_result) -- NOTE: moves to result_callback
        end

        return
      end

      running = running + 1

      iteratee(elem.right, only_once(iteratee_callback), elem.left, obj)
    end
    looping = false
  end

  replenish()
end

-- import once from './once.js'
-- import iterator from './iterator.js'
-- import onlyOnce from './onlyOnce.js'
-- import {isAsyncGenerator, isAsyncIterable} from './wrapAsync.js'
-- import asyncEachOfLimit from './asyncEachOfLimit.js'
-- import breakLoop from './breakLoop.js'
--
-- export default (limit) => {
--     return (obj, iteratee, callback) => {
--         callback = once(callback);
--         if (limit <= 0) {
--             throw new RangeError('concurrency limit cannot be less than 1')
--         }
--         if (!obj) {
--             return callback(null);
--         }
--         if (isAsyncGenerator(obj)) {
--             return asyncEachOfLimit(obj, limit, iteratee, callback)
--         }
--         if (isAsyncIterable(obj)) {
--             return asyncEachOfLimit(obj[Symbol.asyncIterator](), limit, iteratee, callback)
--         }
--         var nextElem = iterator(obj);
--         var done = false;
--         var canceled = false;
--         var running = 0;
--         var looping = false;
--
--         function iterateeCallback(err, value) {
--             if (canceled) return
--             running -= 1;
--             if (err) {
--                 done = true;
--                 callback(err);
--             }
--             else if (err === false) {
--                 done = true;
--                 canceled = true;
--             }
--             else if (value === breakLoop || (done && running <= 0)) {
--                 done = true;
--                 return callback(null);
--             }
--             else if (!looping) {
--                 replenish();
--             }
--         }
--
--         function replenish () {
--             looping = true;
--             while (running < limit && !done) {
--                 var elem = nextElem();
--                 if (elem === null) {
--                     done = true;
--                     if (running <= 0) {
--                         callback(null);
--                     }
--                     return;
--                 }
--                 running += 1;
--                 iteratee(elem.value, elem.key, onlyOnce(iterateeCallback));
--             }
--             looping = false;
--         }
--
--         replenish();
--     };
-- }
