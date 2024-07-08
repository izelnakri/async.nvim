local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.filter", function()
  after_each(function()
    wait(5)
  end)

  it("works on list collection", function()
    Callback.filter({ 3, 4, 2, 1 }, function(value, callback, index)
      Timers.set_timeout(function()
        callback(nil, (value % 2) == 1)
      end, index * 15)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.same(result, { 3, 1 })
    end)

    wait(150)
  end)

  it("doesnt mutate the original list collection", function()
    local list = { 3, 4, 2, 1 }
    Callback.filter(list, function(value, callback)
      callback(nil, (value % 2) == 1)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.same(result, { 3, 1 })
    end)

    wait(0, function()
      assert.are.same(list, { 3, 4, 2, 1 })
    end)
  end)

  it("can filter an object correctly", function()
    local me = { name = "Izel", points = 32, last_name = "Nakri", active = true }

    Callback.filter(me, function(value, callback)
      Timers.set_timeout(function()
        callback(nil, type(value) == "string")
      end, 50)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.same(result, { name = "Izel", last_name = "Nakri" })
    end)

    wait(250)
  end)

  it("can error early", function()
    local call_order = {}

    Callback.filter({ 3, 1, 2 }, function(element, callback)
      table.insert(call_order, element)
      if element == 1 then
        return callback("error")
      end

      return callback(nil)
    end, function(err, result)
      assert.are.equal(err, "error")
      assert.are.same(call_order, { 3, 1 })
      assert.are.equal(result, nil)
    end)
  end)

  it("can be cancelled", function()
    local call_order = {}

    Callback.filter({ 3, 1, 2, 4, 5 }, function(element, callback)
      table.insert(call_order, element)

      Timers.set_timeout(function()
        if element == 2 then
          return callback(false)
        end

        return callback(nil)
      end, 25)
    end, function()
      assert.True(false, "should not get here")
    end)

    wait(150, function()
      assert.are.equal(err, nil)
      assert.are.same(call_order, { 3, 1, 2, 4, 5 })
      assert.are.equal(result, nil)
    end)
  end)

  it("should finish before Callback.filter_series and Callback.filter_limit", function()
    local task_duration = 100
    local list = { "a", "b", "c", "d", "e" }
    local result = {}
    local finished_operations = {}

    local filter_timer = Timers.track_time()
    Callback.filter(list, function(value, callback)
      table.insert(result, value)
      Timers.set_timeout(function()
        callback(nil, true)
      end, task_duration)
    end, function()
      filter_timer = filter_timer.stop()
      table.insert(finished_operations, "filter")
    end)

    wait(task_duration * #list)

    local filter_limit_timer = Timers.track_time()
    Callback.filter_limit(list, 3, function(value, callback)
      table.insert(result, value)
      Timers.set_timeout(function()
        callback(nil, true)
      end, task_duration)
    end, function()
      filter_limit_timer = filter_limit_timer.stop()
      table.insert(finished_operations, "filter_limit")
    end)

    wait(task_duration * 3)

    local filter_series_timer = Timers.track_time()
    Callback.filter_series(list, function(value, callback)
      table.insert(result, value)
      Timers.set_timeout(function()
        callback(nil, true)
      end, task_duration)
    end, function()
      filter_series_timer = filter_series_timer.stop()
      table.insert(finished_operations, "filter_series")
    end)

    wait(task_duration * (#list + 1))

    assert.are.same(finished_operations, { "filter", "filter_limit", "filter_series" })
    assert.True(filter_timer.duration < filter_limit_timer.duration)
    assert.True(filter_timer.duration < filter_series_timer.duration)
    assert.True(filter_limit_timer.duration < filter_series_timer.duration)
  end)
end)

-- describe("filter", () => {
--     function makeIterator(array){
--         var nextIndex;
--         let iterator = {
--             next(){
--                 return nextIndex < array.length ?
--                     {value: array[nextIndex++], done: false} :
--                     {done: true};
--             }
--         };
--         iterator[Symbol.iterator] = function() {
--             nextIndex = 0; // reset iterator
--             return iterator;
--         };
--         return iterator;
--     }
--
--     it('filter iterator', (done) => {
--         var a = makeIterator([500, 20, 100]);
--         async.filter(a, (x, callback) => {
--             setTimeout(() => {
--                 callback(null, x > 20);
--             }, x);
--         }, (err, results) => {
--             expect(err).to.equal(null);
--             expect(results).to.eql([500, 100]);
--             done();
--         });
--     });
-- });
