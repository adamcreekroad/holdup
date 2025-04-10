local counter_key = KEYS[1]

local limit = tonumber(ARGV[1])
local duration = tonumber(ARGV[2])

local counter = redis.call('GET', counter_key)

if counter then
  -- If the window is currently active, determine the current state of it and return appropriately.
  counter = tonumber(counter)

  -- TODO: Investigate this more. An edge case occurs where the key still exists and hasn't expired, yet the PTTL is
  -- less than 0 -- which signifies the key has expired or doesn't exist. Could be potentially the TTL is in the
  -- μs range so technically it still exists, but can't be represented within Redis' precision? ¯\_(ツ)_/¯
  local counter_pttl = redis.call('PTTL', counter_key)
  if counter_pttl < 0 then
    counter_pttl = 0
  end

  local status
  if counter >= limit then
    status = 1
  else
    status = 0
  end

  return { status, limit - counter, string.format("%.9f", counter_pttl / 1000) }
else
  -- Otherwise, return an empty status
  return { 0, limit, nil }
end
