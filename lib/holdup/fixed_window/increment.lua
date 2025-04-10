local counter_key = KEYS[1]

local limit = tonumber(ARGV[1])
local duration = math.ceil(tonumber(ARGV[2]) * 1000)
local count = tonumber(ARGV[3])

local counter = tonumber(redis.call('GET', counter_key) or 0)
local counter_pttl = redis.call('PTTL', counter_key)

-- If we're starting with an empty window, set the PTTL to the duration
if counter_pttl < 0 then
  counter_pttl = duration
end

local reset_after = string.format("%.9f", counter_pttl / 1000)

-- First check if all slots have already been used up -- if it is, return THROTTLED status
local remaining = math.max(limit - counter, 0)
if remaining == 0 then
  return { 1, remaining, reset_after }
end

-- Next check if the requested slots would exceed the availability in the window -- if it would, return FAILURE status
local new_counter = counter + count
if new_counter > limit then
  return { 2, remaining, reset_after }
end

-- Otherwise all is clear to increment and return a successful state.
redis.call('SET', counter_key, '0', 'NX', 'PX', duration)
counter = redis.call('INCRBY', counter_key, count)

return { 0, limit - counter, reset_after }
