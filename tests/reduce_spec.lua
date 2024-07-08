local Timers = require("callback.utils.timers")
local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.reduce", function()
  after_each(function()
    wait(5)
  end)

  it("works synchronously", function()
    local call_order = {}
    local operation_result
    Callback.reduce(
      { 2, 4, 5 },
      function(result, value, callback, index)
        table.insert(call_order, index)
        table.insert(call_order, value)

        callback(nil, result + value) -- callback(nil, result + value)
      end,
      0,
      function(err, result)
        operation_result = result
        assert.are.equal(err, nil)
        assert.are.equal(result, 11)
      end
    )

    wait(0, function()
      assert.are.same(call_order, { 1, 2, 2, 4, 3, 5 })
      assert.are.equal(operation_result, 11)
    end)
  end)

  it("result gets built correctly inside callbacks that have callbacks", function()
    local call_order = {}
    local operation_result
    Callback.reduce(
      { 2, 4, 5 },
      function(result, value, callback, index)
        table.insert(call_order, index)
        table.insert(call_order, value)
        Timers.set_timeout(function()
          callback(nil, result + value)
        end, 25 * value)
      end,
      0,
      function(err, result)
        operation_result = result
        assert.are.equal(err, nil)
        assert.are.equal(result, 11)
      end
    )

    wait(300, function()
      assert.are.same(call_order, { 1, 2, 2, 4, 3, 5 })
      assert.are.equal(operation_result, 11)
    end)
  end)

  it("works when collection is an object instead of a list", function()
    local object = { name = "Izel", last_name = "Nakri", points = 32 }
    local call_order = {}
    local operation_result
    Callback.reduce(object, function(result, value, callback, key)
      table.insert(call_order, key)
      table.insert(call_order, value)
      Timers.set_timeout(function()
        callback(
          nil,
          vim.tbl_extend("force", result, {
            [key] = value,
          })
        )
      end, 50)
    end, { admin = true }, function(err, result)
      operation_result = result
      assert.are.equal(err, nil)
      assert.are.same(result, {
        admin = true,
        name = "Izel",
        last_name = "Nakri",
        points = 32,
      })
    end)

    wait(200, function()
      assert.are.same(call_order, { "last_name", "Nakri", "name", "Izel", "points", 32 })
      assert.are.same(operation_result, {
        admin = true,
        name = "Izel",
        last_name = "Nakri",
        points = 32,
      })
    end)
  end)

  it("can handle error", function()
    Callback.reduce(
      { 1, 2, 3 },
      function(result, value, callback)
        callback("error")
      end,
      0,
      function(err, b)
        assert.are.equal(err, "error")
      end
    )
  end)

  it("can handle cancel case", function(done)
    local call_order = {}
    Callback.reduce(
      { 3, 5, 2 },
      function(result, value, callback, index)
        table.insert(call_order, value)
        if index == 2 then
          callback(false, result + value)
        else
          callback(nil, result + value)
        end
      end,
      0,
      function()
        assert.True(false, "should not get here")
      end
    )

    wait(0, function()
      assert.are.same(call_order, { 3, 5 })
    end)
  end)
end)

-- var async = require('../lib');
-- var {expect} = require('chai');
-- var assert = require('assert');
--
-- describe('reduce', () => {
--     it('reduceRight', (done) => {
--         var call_order = [];
--         var arr = [1,2,3];
--         async.reduceRight(arr, 0, (a, x, callback) => {
--             call_order.push(x);
--             callback(null, a + x);
--         }, (err, result) => {
--             expect(result).to.equal(6);
--             expect(call_order).to.eql([3,2,1]);
--             expect(arr).to.eql([1,2,3]);
--             done();
--         });
--     });
--
--     it('reduceRight canceled', (done) => {
--         var call_order = [];
--         async.reduceRight([1,2,3], 0, (a, x, callback) => {
--             call_order.push(x);
--             callback(x === 2 ? false : null, a + x)
--         }, () => {
--             throw new Error('should not get here');
--         });
--
--         setTimeout(() => {
--             expect(call_order).to.eql([3, 2]);
--             done();
--         }, 25);
--     });
-- });
