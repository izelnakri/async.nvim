local Callback = require("callback")
local wait = require("tests.utils.wait")

describe("Callback.run", function()
  after_each(function()
    wait(5)
  end)

  it("basic usage of running already async functions", function()
    local result = Callback.run(
      vim.uv.fs_open,
      "README.md",
      "r",
      438,
      function(err, fd) -- NOTE: Maybe change this to: err, callback, result
        return Callback.waterfall({
          Callback.apply(vim.uv.fs_fstat, fd),
          function(stat, next) -- NOTE: Can I also refactor this one with Callback.apply?
            return vim.uv.fs_read(fd, stat.size, 0, next)
          end,
          function(data, callback)
            vim.uv.fs_close(fd, callback)
          end,
        }, function(err, result)
          assert.are.equal(err, nil)
          assert.are.equal(result, true)
        end)
      end
    )

    assert.are.same(result, {})
  end)

  it("can be run on functions that have Callback.apply -ied  to them", function()
    local applied_func = Callback.apply(vim.uv.fs_open, "README.md", "r", 438)
    local result_two = Callback.run(applied_func, function(err, fd)
      return Callback.waterfall({
        Callback.apply(vim.uv.fs_fstat, fd),
        function(stat, next) -- NOTE: Can I also refactor this one with Callback.apply?
          return vim.uv.fs_read(fd, stat.size, 0, next)
        end,
        function(data, callback)
          return vim.uv.fs_close(fd, callback)
        end,
      }, function(err, result)
        assert.are.equal(err, nil)
        assert.are.equal(result, true)
      end)
    end)

    assert.are.same(result_two, {})
  end)
end)
