require("async.test")

local Timers = require("timers")
local Callback = require("callback")
local deep_equal = require("tests.utils.deep_equal")
local wait = require("tests.utils.wait")

describe("Callback.each_limit", function()
  after_each(function()
    wait(5)
  end)

  async_it("it works with object", function()
    local args = {}
    Callback.each_limit({ a = 1, b = 2, c = 3, d = 4 }, 2, function(value, callback, key)
      Timers.set_timeout(function()
        table.insert(args, key)
        table.insert(args, value)
        callback(nil, key)
      end, value * 15)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, "d")
      deep_equal(args, { "a", 1, "b", 2, "c", 3, "d", 4 })
      done()
    end)
  end)

  async_it("works with array", function()
    local args = {}
    Callback.each_limit({ "a", "b" }, 1, function(value, cb, index)
      table.insert(args, index)
      table.insert(args, value)
      cb(nil, "z")
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, "z")
      assert.are.same(args, { 1, "a", 2, "b" })
      done()
    end)
  end)

  async_it("empty object", function()
    Callback.each_limit({}, 2, function(_, callback)
      assert.True(false, "iteratee should not be called")
      callback()
    end, function(err)
      assert.True(true, "should call callback")
      done()
    end)
  end)

  async_it("is with limit that exceeds to size", function()
    local args = {}
    local obj = { a = 1, b = 2, c = 3, d = 4, e = 5 }
    Callback.each_limit(obj, 10, function(value, callback, key)
      Timers.set_timeout(function()
        table.insert(args, key)
        table.insert(args, value)
        callback(nil, key)
      end, value * 25)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, "e")
      deep_equal(args, { "a", 1, "b", 2, "c", 3, "d", 4, "e", 5 })
      done()
    end)
  end)

  async_it("is with limit that equals to size", function()
    local args = {}
    local obj = { a = 1, b = 2, c = 3, d = 4, e = 5 }
    Callback.each_limit(obj, 5, function(value, callback, key)
      Timers.set_timeout(function()
        table.insert(args, key)
        table.insert(args, value)
        callback(nil, key)
      end, value * 25)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, "e")
      deep_equal(args, { "a", 1, "b", 2, "c", 3, "d", 4, "e", 5 })
      done()
    end)
  end)

  -- TODO: This is assert.throws example. Should check for message: concurrency limit
  -- it("is with 0 limit", function()
  --   local obj = { a = 1, b = 2, c = 3, d = 4, e = 5 }
  --   Callback.each_limit(obj, 0, function(_, _, callback)
  --     assert.True(false, "iteratee should not be called")
  --     callback()
  --   end, function(err)
  --     assert.are.equal(err, nil)
  --     assert.True(true, "should call callback")
  --   end)
  --   wait(150, function() end)
  -- end)

  async_it("is with no limit(infinity)", function()
    local list = {}
    local count = 0
    for i = 1, 100 do
      table.insert(list, i)
    end

    Callback.each_limit(list, math.huge, function(value, callback)
      count = count + 1
      callback(nil, value)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 100)
      assert.are.equal(count, 100)
      done()
    end)
  end)

  async_it("callback error value", function()
    local obj = { a = 1, b = 2, c = 3, d = 4, e = 5 }
    local call_order = {}

    Callback.each_limit(obj, 3, function(value, callback, key)
      table.insert(call_order, value)
      table.insert(call_order, key)
      if value == 2 then
        callback("error")
      end
    end, function(err)
      assert.are.same(call_order, { 1, "a", 2, "b" })
      assert.are.equal(err, "error")
      done()
    end)
  end)

  it("with no callback provided", function()
    Callback.each_limit({ a = 1 }, 2, function(value, callback, key)
      assert.are.equal(key, "a")
      assert.are.equal(value, 1)
      callback()
    end)
  end)

  it("can be canceled", function(done)
    local obj = { a = 1, b = 2, c = 3, d = 4, e = 5 }
    local call_order = {}

    Callback.each_limit(obj, 3, function(value, callback, key)
      table.insert(call_order, value)
      table.insert(call_order, key)
      if value == 2 then
        return callback(false)
      end

      callback()
    end, function()
      assert.True(false, "should not get here")
    end)

    wait(0, function()
      assert.are.same(call_order, { 1, "a", 2, "b" })
    end)
  end)

  it("can be canceled (async)", function()
    local obj = { a = 1, b = 2, c = 3, d = 4, e = 5 }
    local call_order = {}

    Callback.each_limit(obj, 3, function(value, callback, key)
      table.insert(call_order, value)
      table.insert(call_order, key)

      Timers.set_timeout(function()
        if value == 2 then
          return callback(false)
        end
        callback()
      end)
    end, function()
      assert.True(false, "should not get here")
    end)
    wait(0, function()
      assert.True(#call_order == 6 or #call_order == 8)
    end)
  end)

  it("can be canceled (async, array)", function(done)
    local obj = { "a", "b", "c", "d", "e" }
    local call_order = {}

    Callback.each_limit(obj, 3, function(value, callback, index)
      table.insert(call_order, index)
      table.insert(call_order, value)
      Timers.set_timeout(function()
        if value == "b" then
          return callback(false)
        end
        callback()
      end)
    end, function()
      assert.True(false, "should not get here")
    end)
    wait(0, function()
      assert.True(#call_order == 6 or #call_order == 8)
    end)
  end)

  it("can be canceled (async, w/ error)", function()
    local obj = { a = 1, b = 2, c = 3, d = 4, e = 5 }
    local call_order = {}

    Callback.each_limit(obj, 3, function(value, callback, key)
      table.insert(call_order, key)
      table.insert(call_order, value)
      Timers.set_timeout(function()
        if value == 2 then
          return callback(false)
        elseif value == 3 then
          return callback("fail")
        end

        callback()
      end)
    end, function()
      assert.True(false, "should not get here")
    end)

    wait(0, function()
      assert.True(#call_order == 6 or #call_order == 8)
      assert.are.same(call_order, { "a", 1, "b", 2, "c", 3, "d", 4 })
    end)
  end)
end)

--     it('forEachOfLimit with Map (iterators)', function(done) {
--         if (typeof Map !== 'function')
--             return done();
--
--         var args = [];
--         var map = new Map();
--         map.set(1, "a");
--         map.set(2, "b");
--         async.forEachOfLimit(map, 1, forEachOfIteratee.bind(this, args), (err) => {
--             if (err) throw err;
--             expect(args).to.eql([0, [1, "a"], 1, [2, "b"]]);
--             done();
--         });
--     });
