# frozen_string_literal: true

require_relative "lib/holdup/version"

Gem::Specification.new do |spec|
  spec.name = "holdup"
  spec.version = Holdup::VERSION
  spec.authors = ["adamcreekroad"]
  spec.email = ["adam.code@harge.world"]

  spec.summary = "Performant and accurate rate limiting for Ruby applications."
  spec.description = "Performant and accurate rate limiting for Ruby applications."
  spec.homepage = "https://github.com/adamcreekroad/holdup"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/adamcreekroad/holdup"
  spec.metadata["changelog_uri"] = "https://github.com/adamcreekroad/holdup/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/adamcreekroad/holdup/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
