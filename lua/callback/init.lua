local any = require("callback.any")
local any_limit = require("callback.any_limit")
local any_series = require("callback.any_series")
local apply = require("callback.apply")
local auto = require("callback.auto")
local build = require("callback.build")
local build_task = require("callback.build_task")
local each = require("callback.each")
local each_limit = require("callback.each_limit")
local each_series = require("callback.each_series")
local every = require("callback.every")
local every_limit = require("callback.every_limit")
local every_series = require("callback.every_series")
local filter = require("callback.filter")
local filter_limit = require("callback.filter_limit")
local filter_series = require("callback.filter_series")
local forever = require("callback.forever")
local log = require("callback.log")
local map = require("callback.map")
local map_limit = require("callback.map_limit")
local map_series = require("callback.map_series")
local parallel = require("callback.parallel")
local parallel_limit = require("callback.parallel_limit")
local race = require("callback.race")
local reduce = require("callback.reduce")
local reduce_right = require("callback.reduce_right")
local resolve = require("callback.resolve")
local run = require("callback.run")
local series = require("callback.series")
local times = require("callback.times")
local times_limit = require("callback.times_limit")
local times_series = require("callback.times_series")
local try_each = require("callback.try_each")
local waterfall = require("callback.waterfall")

local Callback = {}

Callback.any = any
Callback.any_limit = any_limit
Callback.any_series = any_series
Callback.apply = apply
Callback.auto = auto
Callback.build = build
Callback.build_task = build_task
Callback.each = each
Callback.each_limit = each_limit
Callback.each_series = each_series
Callback.every = every
Callback.every_limit = every_limit
Callback.every_series = every_series
Callback.filter = filter
Callback.filter_limit = filter_limit
Callback.filter_series = filter_series
Callback.forever = forever
Callback.log = log
Callback.map = map
Callback.map_limit = map_limit
Callback.map_series = map_series
Callback.parallel = parallel
Callback.parallel_limit = parallel_limit
Callback.race = race
Callback.reduce = reduce
Callback.reduce_right = reduce_right
Callback.resolve = resolve
Callback.run = run
Callback.series = series
Callback.times = times
Callback.times_limit = times_limit
Callback.times_series = times_series
Callback.try_each = try_each
Callback.waterfall = waterfall

function Callback.setup()
  return Callback
end

return Callback
