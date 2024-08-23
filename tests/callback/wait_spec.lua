local Timers = require("timers")
local wait = require("tests.utils.wait")

describe("wait test helper", function()
  it("should work correctly", function()
    local timer = Timers.track_time()

    wait(100)

    timer = timer.stop()

    assert.True(timer.duration < 120, "duration is " .. timer.duration)

    local timer = Timers.track_time()

    wait(2000)

    timer = timer.stop()

    assert.True(timer.duration < 2005, "2nd duration is " .. timer.duration)

    local timer = Timers.track_time()

    wait(1000)

    timer = timer.stop()

    assert.True(timer.duration < 1005, "3rd duration is " .. timer.duration)
  end)
end)
