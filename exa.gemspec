# frozen_string_literal: true

require_relative "lib/exa/version"

Gem::Specification.new do |spec|
  spec.name = "exa-ai"
  spec.version = Exa::VERSION
  spec.authors = ["Benjamin Jackson"]
  spec.email = ["ben@hearmeout.co"]

  spec.summary = "Ruby client for the Exa.ai API"
  spec.description = "A Ruby gem for interacting with the Exa.ai search and discovery API"
  spec.homepage = "https://github.com/benjaminjackson/exa-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/benjaminjackson/exa-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/benjaminjackson/exa-ruby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem
  spec.files = Dir.glob("{lib,exe}/**/*") + %w[LICENSE README.md]
  spec.require_paths = ["lib"]

  # Executables
  spec.bindir = "exe"
  spec.executables = ["exa-ai"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "ld-eventsource", "~> 2.0"
  spec.add_dependency "toon-ruby", "~> 0.1"

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-fail-fast", "~> 0.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "bundler-audit", "~> 0.9"
  spec.add_development_dependency "dotenv", "~> 3.0"
end
