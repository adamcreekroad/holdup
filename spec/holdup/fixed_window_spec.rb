# frozen_string_literal: true

RSpec.describe(Holdup::FixedWindow) do
  let(:limiter) { described_class.new(key:, limit:, duration:, redis:) }
  let(:key) { "foo" }
  let(:limit) { 12 }
  let(:duration) { 2 }

  before do
    RedisClient.new.call("DEL", "holdup:fixed_window:#{key}:counter")
  end

  shared_examples "info and increment!" do
    before(:context) do
      # Ensure we test the script loading for each redis instance type
      RedisClient.new.call("SCRIPT", "FLUSH", "SYNC")
    end

    let(:count) { 1 }

    it "returns an empty state when no tokens have been added to the window" do
      expect(limiter.info).to match_rate_limit_info(remaining: limit, reset_after: nil, retry_after: nil)
    end

    it "adds one token to the window" do
      expect(limiter.increment!).to match_rate_limit_info(remaining: limit - 1, reset_after: 1..2)
    end

    it "adds several tokens to the window at once" do
      expect(limiter.increment!(count: 5)).to match_rate_limit_info(remaining: limit - 5, reset_after: 1..2)
    end

    it "returns the requests remaining and reset_after when some requests have been used" do
      (limit / 2).times { limiter.increment! }

      expect(limiter.info).to match_rate_limit_info(remaining: limit / 2, reset_after: 1..2, retry_after: nil)
    end

    it "returns no requests remaining with both reset_after and retry after when all requests have been used" do
      limit.times { limiter.increment! }

      expect(limiter.info).to match_rate_limit_info(remaining: 0, reset_after: 1..2, retry_after: 1..2)
    end

    it "raises an error when attempting to add a token when the window is full" do
      limit.times { limiter.increment! }

      expect { limiter.increment! }.to raise_error do |error|
        expect(error).to be_a(Holdup::LimitedError)
      end
    end

    it "raises an error when attempting to add more tokens than the remaining capacity in the window" do
      (limit / 2).times { limiter.increment! }

      expect { limiter.increment!(count: (limit / 2) + 1) }.to raise_error do |error|
        expect(error).to be_a(Holdup::LimitedError)
        expect(error.info).to match_rate_limit_info(remaining: limit / 2, reset_after: 1..2, retry_after: 1..2)
      end
    end

    context "resetting" do
      let(:duration) { 0.25 }

      it "resets after the duration" do
        limiter.increment!
        sleep(limiter.info.reset_after + 0.001)
        expect(limiter.info).to match_rate_limit_info(remaining: limit, reset_after: nil, retry_after: nil)
      end

      it "resets after the duration when limited" do
        expect { (limit + 1).times { limiter.increment! } }.to raise_error(Holdup::LimitedError)
        expect(limiter.info).to match_rate_limit_info(remaining: 0, reset_after: 0..duration, retry_after: 0..duration)

        sleep(limiter.info.retry_after + 0.001)
        expect(limiter.info).to match_rate_limit_info(remaining: limit, reset_after: nil, retry_after: nil)
      end
    end
  end

  context "when using Redis" do
    let(:redis) { Redis.new }

    include_examples "info and increment!"
  end

  context "when using RedisClient" do
    let(:redis) { RedisClient.new }

    include_examples "info and increment!"
  end

  context "when using ConnectionPool" do
    let(:redis) { ConnectionPool.new { RedisClient.new } }

    include_examples "info and increment!"
  end
end
