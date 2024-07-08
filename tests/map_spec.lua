local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.filter", function()
  after_each(function()
    wait(5)
  end)

  it("works on list collection", function()
    Callback.map({ 3, 4, 2, 1 }, function(value, callback, index)
      Timers.set_timeout(function()
        callback(nil, value * 2)
      end, index * 15)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.same(result, { 6, 8, 4, 2 })
    end)
  end)

  it("doesnt mutate the original list collection", function()
    local list = { 3, 4, 2, 1 }
    Callback.map(list, function(value, callback)
      callback(nil, value * 2)
    end, function(err, result)
      assert.are.equal(err, nil)
      assert.are.same(result, { 6, 8, 4, 2 })
    end)
  end)

  it("can error", function()
    Callback.map({ 3, 1, 2 }, function(element, callback)
      if element == 1 then
        return callback("error")
      end

      return callback(nil, element * 2)
    end, function(err, result)
      assert.are.equal(err, "error")
      assert.are.same(result, { 6 })
    end)
  end)

  it("can be cancelled", function()
    local call_order = {}

    Callback.map({ 3, 1, 2, 4, 5 }, function(element, callback)
      table.insert(call_order, element)

      Timers.set_timeout(function()
        if element == 2 then
          return callback(false)
        end

        return callback(nil, element * 2)
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

  it("should finish before Callback.map_series and Callback.map_limit", function()
    local task_duration = 100
    local list = { "a", "b", "c", "d", "e" }
    local result = {}
    local finished_operations = {}

    local map_timer = Timers.track_time()
    Callback.filter(list, function(value, callback, index)
      table.insert(result, value)
      Timers.set_timeout(function()
        callback(nil, index * 2)
      end, task_duration)
    end, function()
      map_timer = map_timer.stop()
      table.insert(finished_operations, "map")
    end)

    wait(task_duration * #list)

    local map_limit_timer = Timers.track_time()
    Callback.map_limit(list, 3, function(value, callback, index)
      table.insert(result, value)
      Timers.set_timeout(function()
        callback(nil, index * 2)
      end, task_duration)
    end, function()
      map_limit_timer = map_limit_timer.stop()
      table.insert(finished_operations, "map_limit")
    end)

    wait(task_duration * 3)

    local map_series_timer = Timers.track_time()
    Callback.filter_series(list, function(value, callback, index)
      table.insert(result, value)
      Timers.set_timeout(function()
        callback(nil, index * 2)
      end, task_duration)
    end, function()
      map_series_timer = map_series_timer.stop()
      table.insert(finished_operations, "map_series")
    end)

    wait(task_duration * (#list + 1))

    assert.are.same(finished_operations, { "map", "map_limit", "map_series" })
    assert.True(map_timer.duration < map_limit_timer.duration)
    assert.True(map_timer.duration < map_series_timer.duration)
    assert.True(map_limit_timer.duration < map_series_timer.duration)
  end)
end)

-- describe("map", () => {
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
