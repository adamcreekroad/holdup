# frozen_string_literal: true

RSpec::Matchers.define(:match_rate_limit_info) do |expected|
  define_method :matches_remaining? do |actual|
    return true unless expected.key?(:remaining)

    expected[:remaining] == actual
  end

  define_method :matches_reset_after? do |actual|
    return true unless expected.key?(:reset_after)

    if expected[:reset_after].is_a?(Range)
      expected[:reset_after].include?(actual)
    else
      expected[:reset_after] == actual
    end
  end

  define_method :matches_retry_after? do |actual|
    return true unless expected.key?(:retry_after)

    if expected[:retry_after].is_a?(Range)
      expected[:retry_after].include?(actual)
    else
      expected[:retry_after] == actual
    end
  end

  match do |actual|
    matches_remaining?(actual.remaining) &&
      matches_reset_after?(actual.reset_after) &&
      matches_retry_after?(actual.retry_after)
  end
end

module RateLimitInfoHelper
  # Stubs the provided method on the caller to raise a LimitReachedError
  #
  # RSpec does not provide a way to write custom sub/expectations so we need to also need the `receive`
  def receive_and_be_limited(receiver, message: "Too Many Requests")
    info = RateLimiter::LimitInfo.new(limit: 100, remaining: 0, reserved: 0, retry_after: 1, reset_after: 20)
    error = RateLimiter::LimitReachedError.new(message, info)

    receiver.and_raise(error)
  end
end

RSpec.configure do |config|
  config.include(RateLimitInfoHelper)
end
