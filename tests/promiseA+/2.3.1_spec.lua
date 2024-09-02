require("async.test")

local dummy = { dummy = "dummy" }
local Promise = require("promise")

describe(
  "2.3.1: If `promise` and `x` refer to the same object, reject `promise` with a `TypeError' as the reason.",
  function()
    async_it("via return from a fulfilled promise", function(done)
      local promise

      promise = Promise.resolve(dummy):and_then(function()
        return promise
      end)

      promise:and_then(nil, function(reason)
        assert.is_truthy(string.find(reason, "TypeError"))
        done()
      end)
    end)

    async_it("via return from a rejected promise", function(done)
      local promise

      promise = Promise.reject(dummy):and_then(nil, function()
        return promise
      end)

      promise:and_then(nil, function(reason)
        assert.is_truthy(string.find(reason, "TypeError"))
        done()
      end)
    end)
  end
)
