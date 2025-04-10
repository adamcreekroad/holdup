# frozen_string_literal: true

require "digest"

module Holdup
  # Rate limiter implementation using the Fixed Window algorithm.
  #
  # Limiting is achieved by allowing a maximum number of tokens within a static period of time. A window has a limit,
  # and duration. Once the first token is added, the window `opens`, and tokens can be added up to the limit. Once that
  # limit is reached, the window `closes` until the amount of time equal to its duration has passed. The window will not
  # `open` again until another token has been added, which then restarts the cycle.
  class FixedWindow
    # @param key [String] Unique identifier representing the resource being limited
    # @param limit [Integer] Number of tokens that can pass through a window within its duration
    # @param duration [Float] Amount of time (in seconds) that the window lives for
    # @param redis [Redis, RedisClient, ConnectionPool] Redis connection
    #
    # @return [Holdup::FixedWindow]
    def initialize(key:, limit:, duration:, redis:)
      @key = key
      @counter_key = "holdup:fixed_window:#{key}:counter"

      @limit = limit
      @duration = duration
      @redis = redis
    end

    INFO_SCRIPT_CODE = File.read(File.join(__dir__, "fixed_window", "info.lua")).freeze
    INFO_SCRIPT_HASH = Digest::SHA1.hexdigest(INFO_SCRIPT_CODE).freeze

    # Returns the current state of the window
    #
    # @return [Holdup::LimitInfo]
    def info
      begin
        status, remaining, reset_after = redis.with do |connection|
          connection.call("EVALSHA", INFO_SCRIPT_HASH, 1, counter_key, limit, duration)
        end
      rescue Redis::CommandError, RedisClient::CommandError => e
        if e.message.include?("NOSCRIPT")
          redis.with { _1.call("SCRIPT", "LOAD", INFO_SCRIPT_CODE) }
          retry
        end

        raise
      end

      reset_after = reset_after&.to_f
      retry_after = reset_after if status == Holdup::Status::THROTTLED
      Holdup::LimitInfo.new(limit:, remaining:, reset_after:, retry_after:)
    end

    INCREMENT_SCRIPT_CODE = File.read(File.join(__dir__, "fixed_window", "increment.lua")).freeze
    INCREMENT_SCRIPT_HASH = Digest::SHA1.hexdigest(INCREMENT_SCRIPT_CODE).freeze

    # Adds the number of tokens to the window if there is enough room, otherwise raises an error
    #
    # @raise [Holdup::LimitedError] when the window is full or there is not enough room for the tokens
    #
    # @param count [Integer] number of tokens to add to the window
    #
    # @return [Holdup::LimitInfo]
    def increment!(count: 1)
      begin
        status, remaining, reset_after = redis.with do |connection|
          connection.call("EVALSHA", INCREMENT_SCRIPT_HASH, 1, counter_key, limit, duration, count)
        end
      rescue Redis::CommandError, RedisClient::CommandError => e
        if e.message.include?("NOSCRIPT")
          redis.with { _1.call("SCRIPT", "LOAD", INCREMENT_SCRIPT_CODE) }
          retry
        end

        raise
      end

      reset_after = reset_after&.to_f
      retry_after = reset_after if status != Holdup::Status::SUCCESS
      info = Holdup::LimitInfo.new(limit:, remaining:, reset_after:, retry_after:)

      case status
      when Holdup::Status::SUCCESS
        info
      when Holdup::Status::FAILURE
        raise(Holdup::LimitedError.new("Not enough space for the requested tokens", info))
      when Holdup::Status::THROTTLED
        raise(Holdup::LimitedError.new("No more tokens allowed in the window", info))
      end
    end

    private

    # Unique identifier representing the resource being limited
    #
    # @return [String]
    attr_reader :key
    # Key in redis holding the count of tokens currently in the window
    #
    # @return [String]
    attr_reader :counter_key
    # Number of tokens that can pass through a window within its duration
    #
    # @return [Integer]
    attr_reader :limit
    # Amount of time (in seconds) that the window lives for
    #
    # @return [Float]
    attr_reader :duration
    # Redis connection
    #
    # @return [Redis] if using redis-rb
    # @return [RedisClient] if using redis-client
    # @return [ConnectionPool] if using connection_pool
    attr_reader :redis
  end
end
