-- TODO: Make the inputs *any* value not just tasks, in other words add plain values intead of just tasks and check them
local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")
local null = require("callback.types.null")

describe("Callback.all", function()
  it("works", function()
    local call_order = {}
    Callback.all({
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
      assert.are.same(call_order, { 3, 1, 2 })
      assert.are.same(results, { 1, 2, { 3, 3 } })
    end)

    wait(150)
  end)

  it("empty array calls callback", function()
    Callback.all({}, function(err, results)
      assert.are.equal(err, nil)
      assert.are.same(results, {})
    end)

    wait(50)
  end)

  it("works when there is error", function()
    Callback.all({
      function(callback)
        callback("error", 1)
      end,
      function(callback)
        callback("error2", 2)
      end,
    }, function(err)
      assert.are.equal(err, "error")
    end)

    wait(50)
  end)

  it("doesnt run callback when cancelled", function()
    local call_order = {}
    Callback.all({
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

    wait(25, function()
      assert.are.same(call_order, { "one" })
    end)
  end)

  it("doesnt throw when there is no callback", function()
    Callback.all({
      function(callback)
        callback()
      end,
      function(callback)
        callback()
      end,
    })

    wait(50, function()
      assert.True(true, "no callback is needed")
    end)
  end)

  it("throws correctly when collection is an object", function()
    local call_order = {}

    assert.has_error(function()
      return Callback.all({
        one = function(callback)
          Timers.set_timeout(function()
            table.insert(call_order, 1)
            callback(nil)
          end, 125)
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
        assert.are.same(call_order, { 3, 1, 2 })
        assert.are.same(results, {
          one = null,
          two = 2,
          three = { 3, 3 },
        })
      end)
    end)

    wait(400)
  end)

  it("works on falsy return values correctly", function(done)
    Callback.all({
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

    wait(50)
  end)
end)

-- NOTE: Callback.reflect tests in the future:
--
-- describe('parallel', () => {
--     it('parallel error with reflect', (done) => {
--         async.parallel([
--             async.reflect((callback) => {
--                 callback('error', 1);
--             }),
--             async.reflect((callback) => {
--                 callback('error2', 2);
--             }),
--             async.reflect((callback) => {
--                 callback(null, 2);
--             }),
--             async.reflect((callback) => {
--                 callback('error3');
--             })
--         ],
--         (err, results) => {
--             assert(err === null, err + " passed instead of 'null'");
--             expect(results).to.eql([
--                 { error: 'error', value: 1 },
--                 { error: 'error2', value: 2 },
--                 { value: 2 },
--                 { error: 'error3' },
--             ]);
--             done();
--         });
--     });
--
--     it('parallel object with reflect all (values and errors)', (done) => {
--         var tasks = {
--             one(callback) {
--                 setTimeout(() => {
--                     callback(null, 'one');
--                 }, 200);
--             },
--             two(callback) {
--                 callback('two');
--             },
--             three(callback) {
--                 setTimeout(() => {
--                     callback(null, 'three');
--                 }, 100);
--             },
--             four(callback) {
--                 setTimeout(() => {
--                     callback('four', 4);
--                 }, 100);
--             }
--         };
--
--         async.parallel(async.reflectAll(tasks), (err, results) => {
--             expect(results).to.eql({
--                 one: { value: 'one' },
--                 two: { error: 'two' },
--                 three: { value: 'three' },
--                 four: { error: 'four', value: 4 }
--             });
--             done();
--         })
--     });
--
--     it('parallel empty object with reflect all', (done) => {
--         var tasks = {};
--
--         async.parallel(async.reflectAll(tasks), (err, results) => {
--             expect(results).to.eql({});
--             done();
--         })
--     });
--
--     it('parallel array with reflect all (errors)', (done) => {
--         var tasks = [
--             function (callback) {
--                 callback('one', 1);
--             },
--             function (callback) {
--                 callback('two');
--             },
--             function (callback) {
--                 callback('three', 3);
--             }
--         ];
--
--         async.parallel(async.reflectAll(tasks), (err, results) => {
--             expect(results).to.eql([
--                 { error: 'one', value: 1 },
--                 { error: 'two' },
--                 { error: 'three', value: 3 }
--             ]);
--             done();
--         })
--     });
--
--     it('parallel empty object with reflect all (values)', (done) => {
--         var tasks = {
--             one(callback) {
--                 callback(null, 'one');
--             },
--             two(callback) {
--                 callback(null, 'two');
--             },
--             three(callback) {
--                 callback(null, 'three');
--             }
--         };
--
--         async.parallel(async.reflectAll(tasks), (err, results) => {
--             expect(results).to.eql({
--                 one: { value: 'one' },
--                 two: { value: 'two' },
--                 three: { value: 'three' }
--             });
--             done();
--         })
--     });
-- });
