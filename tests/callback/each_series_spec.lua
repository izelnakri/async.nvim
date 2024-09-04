local Timers = require("timers")
local Callback = require("callback")
local deep_equal = require("tests.utils.deep_equal")
local wait = require("tests.utils.wait")

describe("Callback.each_series", function()
  after_each(function()
    wait(5)
  end)

  it("it works with object", function()
    local args = {}
    Callback.each_series({ a = 1, b = 2 }, function(value, callback, key)
      Timers.set_timeout(function()
        table.insert(args, key)
        table.insert(args, value)
        callback(nil, key)
      end, value * 25)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, "b")
      deep_equal(args, { "a", 1, "b", 2 })
    end)
  end)

  it("works with array", function()
    local args = {}
    Callback.each_series({ "a", "b" }, function(value, cb, index)
      table.insert(args, index)
      table.insert(args, value)
      cb(nil, value)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, "b")
      assert.are.same(args, { 1, "a", 2, "b" })
    end)
  end)

  it("instant resolver", function()
    local args = {}
    Callback.each_series({ a = 1, b = 2 }, function(value, cb, key)
      table.insert(args, key)
      table.insert(args, value)
      cb(nil, value)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 2)
      deep_equal(args, { "a", 1, "b", 2 })
    end)
  end)

  it("empty object", function(done)
    Callback.each_series({}, function(value, callback, key)
      assert.True(false, "iteratee should not be called")
      callback()
    end, function(err)
      assert.True(true, "should call callback")
    end)
  end)

  it("callback error value", function(done)
    Callback.each_series({ a = 1, b = 2 }, function(value, callback, key)
      callback("error")
    end, function(err)
      assert.are.equal(err, "error")
    end)
  end)

  it("with no callback provided", function(done)
    Callback.each_series({ a = 1 }, function(value, callback, key)
      assert.are.equal(key, "a")
      assert.are.equal(value, 1)
      callback()
    end)
  end)
end)

--     it('forEachOfSeries with Set (iterators)', function(done) {
--         if (typeof Set !== 'function')
--             return done();
--
--         var args = [];
--         var set = new Set();
--         set.add("a");
--         set.add("b");
--         async.forEachOfSeries(set, forEachOfIteratee.bind(this, args), (err) => {
--             if (err) throw err;
--             expect(args).to.eql([0, "a", 1, "b"]);
--             done();
--         });
--     });
