--> TODO: Can I differentiate between these two?
-- Callback.reflect(callbackBasedFunc)
-- Callback.reflect(JSON.parse)
-- TODO: Callback.reflect -> Callback:new() { error: , value: , }

local Callback = require("callback")
local wait = require("tests.utils.wait")

local failing_callback_function = function(value, callback)
  return callback("Error: " .. value)
end

local succeeding_callback_function = function(value, callback)
  return callback(nil, value)
end

local failing_callback_function_with_additional_arg = function(param, value, callback)
  return callback("Error: " .. param .. " " .. value)
end

local succeeding_callback_function_with_additional_arg = function(param, value, callback)
  return callback(nil, param .. " " .. value)
end

describe("Callback.apply", function()
  after_each(function()
    wait(5)
  end)

  it("it works on basic iteratee building scenarios", function()
    Callback.each_series(
      { "first-a", "second-b", "third-c" },
      Callback.apply(failing_callback_function),
      function(err, result)
        assert.are.equal(err, "Error: first-a")
        assert.are.equal(result, nil)
      end
    )
    Callback.each_series(
      { "first-a", "second-b", "third-c" },
      Callback.apply(failing_callback_function_with_additional_arg, "test-param"),
      function(err, result)
        assert.are.equal(err, "Error: test-param first-a")
        assert.are.equal(result, nil)
      end
    )

    Callback.each_series(
      { "first-a", "second-b", "third-c" },
      Callback.apply(succeeding_callback_function),
      function(err, result)
        assert.are.equal(err, nil)
        assert.are.equal(result, "third-c")
      end
    )

    Callback.each_series(
      { "first-a", "second-b", "third-c" },
      Callback.apply(succeeding_callback_function_with_additional_arg, "test-param"),
      function(err, result)
        assert.are.equal(err, nil)
        assert.are.equal(result, "test-param third-c")
      end
    )
  end)

  it(
    "it works in conjuction with internal operation parameters when it is built without additional parameters and used in some callback operation as iteratee",
    function()
      local test_collection = { "first-a", "second-b", "third-c" }
      Callback.each_series(
        test_collection,
        Callback.apply(function(value, callback, index, collection, should_be_test_param, should_be_another_param)
          assert.are.equal(value, "first-a")
          assert.are.equal(index, 1)
          assert.are.same(collection, test_collection)
          assert.are.equal(should_be_test_param, nil)
          assert.are.equal(should_be_another_param, nil)

          callback("some-error")
        end),
        function(err, result)
          assert.are.equal(err, "some-error")
          assert.are.equal(result, nil)
        end
      )

      Callback.each_series(
        { "first-a", "second-b", "third-c " },
        Callback.apply(function(value, callback, index, collection, should_be_test_param, should_be_another_param)
          assert.are.equal(value, collection[index])
          assert.are.equal(should_be_test_param, nil)
          assert.are.equal(should_be_another_param, nil)

          callback(nil, "some-result")
        end),
        function(err, result)
          assert.are.equal(err, nil)
          assert.are.equal(result, "some-result")
        end
      )
    end
  )

  it(
    "it works in conjuction with internal operation parameters when it is built with additional parameters and used in some callback operation as iteratee",
    function()
      local test_collection = { "first-a", "second-b", "third-c" }
      Callback.each_series(
        test_collection,
        Callback.apply(
          function(passed_value, value, callback, index, collection, should_be_test_param, should_be_another_param)
            assert.are.equal(passed_value, "test-param")
            assert.are.equal(index, 1)
            assert.are.same(collection, test_collection)
            assert.are.equal(should_be_test_param, nil)
            assert.are.equal(should_be_another_param, nil)

            callback("some-error")
          end,
          "test-param",
          nil,
          "another-param"
        ),
        function(err, result)
          assert.are.equal(err, "some-error")
          assert.are.equal(result, nil)
        end
      )

      Callback.each_series(
        test_collection,
        Callback.apply(function(value, callback, index, collection, should_be_test_param, should_be_another_param)
          assert.are.equal(value, "test-param")
          assert.are.equal(index, 99)
          assert.are.same(collection, { "hello" })
          assert.are.equal(should_be_test_param, "another-param")
          assert.are.equal(should_be_another_param, "first-a")

          callback("some-error")
        end, "test-param", function() end, 99, { "hello" }, "another-param"),
        function(err, result)
          assert.True(false, "should never call since callback is replaced")
        end
      )

      Callback.each_series(
        test_collection,
        Callback.apply(
          function(passed_value, value, callback, index, collection, should_be_test_param, should_be_another_param)
            assert.are.equal(passed_value, "something-else")
            assert.are.equal(value, collection[index])
            assert.are.same(collection, test_collection)
            assert.are.equal(should_be_test_param, nil)
            assert.are.equal(should_be_another_param, nil)

            callback(nil, "some-result")
          end,
          "something-else",
          nil,
          "another-param"
        ),
        function(err, result)
          assert.are.equal(err, nil)
          assert.are.equal(result, "some-result")
        end
      )
    end
  )

  it("can be used in Callback.waterfall method correctly", function()
    local multiply_by_two = function(param, callback)
      return callback(nil, param * 2)
    end

    Callback.waterfall({
      Callback.apply(multiply_by_two, 12),
      function(param, callback)
        callback(nil, param + 1)
      end,
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 25)
    end)

    Callback.waterfall({
      Callback.apply(multiply_by_two, 12),
      Callback.apply(multiply_by_two),
      function(param, callback)
        callback(nil, param + 1)
      end,
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 49)
    end)

    Callback.waterfall({
      Callback.apply(multiply_by_two, 12),
      Callback.apply(multiply_by_two),
      Callback.apply(multiply_by_two),
      function(param, callback)
        callback(nil, param + 1)
      end,
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 97)
    end)

    Callback.waterfall({
      function(callback)
        return callback(nil, 10)
      end,
      Callback.apply(multiply_by_two),
      Callback.apply(multiply_by_two),
      function(param, callback)
        callback(nil, param + 1)
      end,
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 41)
    end)

    Callback.waterfall({
      function(callback)
        return callback(nil, 10)
      end,
      Callback.apply(multiply_by_two),
      multiply_by_two,
      function(param, callback)
        callback(nil, param + 1)
      end,
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 41)
    end)

    local some_middle_func = function(value, second_value, passed_in_value, callback)
      return callback(nil, (passed_in_value - value - second_value))
    end

    Callback.waterfall({
      function(callback)
        return callback(nil, 10)
      end,
      Callback.apply(multiply_by_two),
      multiply_by_two,
      Callback.apply(some_middle_func, 20, 11),
      function(param, callback)
        callback(nil, param + 1)
      end,
    }, function(err, result)
      assert.are.equal(err, nil)
      assert.are.equal(result, 10)
    end)
  end)
end)
