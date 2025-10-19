# frozen_string_literal: true

require_relative "lib/exa/version"

Gem::Specification.new do |spec|
  spec.name = "exa"
  spec.version = Exa::VERSION
  spec.authors = ["Ben"]
  spec.email = ["ben@example.com"]

  spec.summary = "Ruby client for the Exa.ai API"
  spec.description = "A Ruby gem for interacting with the Exa.ai search and discovery API"
  spec.homepage = "https://github.com/ben/exa-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ben/exa-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/ben/exa-ruby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem
  spec.files = Dir.glob("{lib}/**/*") + %w[LICENSE README.md]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.0"

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end
