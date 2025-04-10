# frozen_string_literal: true

require_relative "holdup/version"

# Library of rate limiters implementing common algorithms.
module Holdup
  autoload(:FixedWindow, "holdup/fixed_window")

  # Raised either when limits have been or would be exceeded, blocking execution of the action guarded by limits.
  class LimitedError < StandardError
    # State of the rate limit at the time of the error being raised
    #
    # @return [Holdup::LimitInfo]
    attr_reader :info

    # @param message [String] Reason for being limited
    # @param info [Holdup::LimitInfo] State of the rate limit
    def initialize(message, info)
      super(message)

      @info = info
    end
  end

  # Represents the state of the rate limit at a given point in time
  LimitInfo = Data.define(:limit, :remaining, :reset_after, :retry_after)

  # `Enum` representing the specific return statuses of Lua scripts executed within Redis
  module Status
    # Script was successful in performing its action
    SUCCESS = 0
    # Script was unsuccessful due to currently being at the limit
    THROTTLED = 1
    # Script was unsuccessful in adding more tokens due to a lack of capacity
    FAILURE = 2
  end
end
