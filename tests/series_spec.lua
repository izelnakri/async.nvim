local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")
local null = require("callback.types.null")

describe("Callback.series", function()
  after_each(function()
    wait(5)
  end)

  it("works", function()
    local call_order = {}
    Callback.series({
      function(callback)
        Timers.set_timeout(function()
          table.insert(call_order, 1)
          callback(nil, 1)
        end, 50)
      end,
      function(callback)
        Timers.set_timeout(function()
          table.insert(call_order, 2)
          callback(nil, 2)
        end, 100)
      end,
      function(callback)
        Timers.set_timeout(function()
          table.insert(call_order, 3)
          callback(nil, 3, 3)
        end, 25)
      end,
    }, function(err, results)
      assert.are.equal(err, nil)
      assert.are.same(call_order, { 1, 2, 3 })
      assert.are.same(results, { 1, 2, { 3, 3 } })
    end)
  end)

  it("empty array calls callback", function()
    Callback.series({}, function(err, results)
      assert.are.equal(err, nil)
      assert.are.same(results, {})
    end)
  end)

  it("works when there is error", function()
    Callback.series({
      function(callback)
        callback("error", 1)
      end,
      function(callback)
        callback("error2", 2)
      end,
    }, function(err)
      assert.are.equal(err, "error")
    end)
  end)

  it("doesnt run callback when cancelled", function()
    local call_order = {}
    Callback.series({
      function(callback)
        table.insert(call_order, "one")
        callback(false)
      end,
      function(callback)
        table.insert(call_order, "two")
        callback(nil)
      end,
    }, function()
      assert.True(false, "should not get here")
    end)

    wait(0, function()
      assert.are.same(call_order, { "one" })
    end)
  end)

  it("doesnt throw when there is no callback", function()
    Callback.series({
      function(callback)
        callback()
      end,
      function(callback)
        callback()
      end,
    })

    wait(0, function()
      assert.True(true, "no callback is needed")
    end)
  end)

  it("works correctly when collection is an object", function()
    local call_order = {}

    Callback.series({
      one = function(callback)
        Timers.set_timeout(function()
          table.insert(call_order, 1)
          callback(nil)
        end, 100)
      end,
      two = function(callback)
        Timers.set_timeout(function()
          table.insert(call_order, 2)
          callback(nil, 2)
        end, 350)
      end,
      three = function(callback)
        Timers.set_timeout(function()
          table.insert(call_order, 3)
          callback(nil, 3, 3)
        end, 50)
      end,
    }, function(err, results)
      assert.are.equal(err, nil)
      assert.are.same(call_order, { 1, 3, 2 })
      assert.are.same(results, {
        one = null,
        two = 2,
        three = { 3, 3 },
      })
    end)

    wait(500)
  end)

  it("works on falsy return values correctly", function(done)
    Callback.series({
      function(callback)
        Timers.set_timeout(function()
          callback(nil, false)
        end)
      end,
      function(callback)
        Timers.set_timeout(function()
          callback(nil)
        end)
      end,
      function(callback)
        Timers.set_timeout(function()
          callback(nil, null)
        end)
      end,
    }, function(err, results)
      assert.are.equal(err, nil)
      assert.are.equal(#results, 3)
      assert.are.equal(results[1], false)
      assert.are.equal(results[2], null)
      assert.are.equal(results[3], null)
    end)
  end)
end)

--     it('with reflect', (done) => {
--         var call_order = [];
--         async.series([
--             async.reflect((callback) => {
--                 setTimeout(() => {
--                     call_order.push(1);
--                     callback(null, 1);
--                 }, 25);
--             }),
--             async.reflect((callback) => {
--                 setTimeout(() => {
--                     call_order.push(2);
--                     callback(null, 2);
--                 }, 50);
--             }),
--             async.reflect((callback) => {
--                 setTimeout(() => {
--                     call_order.push(3);
--                     callback(null, 3, 3);
--                 }, 15);
--             })
--         ],
--             (err, results) => {
--                 assert(err === null, err + " passed instead of 'null'");
--                 expect(results).to.eql([
--                     { value: 1 },
--                     { value: 2 },
--                     { value: [3, 3] }
--                 ]);
--                 expect(call_order).to.eql([1, 2, 3]);
--                 done();
--             });
--     });
