# Holdup

Performant and accurate rate limiting for Ruby applications.


## Requirements

Holdup uses Redis, or any other software compatible with Redis' API. The implementation is designed to be as flexible as possible, so it does not have a hard requirement on a specific gem, but is compatible with the following:
- redis
- redis-client
- connection_pool (with either of the above)

## Installation

Add the gem to your Gemfile:

```bash
bundle add holdup
```

## Usage

Holdup provides implementations for common rate limiting algorithms:
- Fixed Window
- Sliding Window (TODO)
- Leaky Bucket (TODO)
- Token Bucket (TODO)

No configuration is necessary, simply pick the algorithm you'd like, specify the limit details, and give it a Redis connection:
```ruby
REDIS = ConnectionPool.new { RedisClient.new }

limiter = Holdup::FixedWindow.new(
  key: 'my-unique-resource',
  limit: 150,
  duration: 30.0,
  redis: REDIS,
)
```

To check the current limiter status:
```ruby
limiter.info
# => #<data Holdup::LimitInfo limit=150, remaining=150, reset_after=nil, retry_after=nil>
```

To use tokens:
```ruby
limiter.increment!
# => #<data Holdup::LimitInfo limit=150, remaining=149, reset_after=30.0, retry_after=nil>
limiter.increment!(count: 5)
# => #<data Holdup::LimitInfo limit=150, remaining=144, reset_after=27.244, retry_after=nil>
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/adamcreekroad/holdup. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/adamcreekroad/holdup/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Holdup project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/adamcreekroad/holdup/blob/main/CODE_OF_CONDUCT.md).
