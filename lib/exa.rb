# frozen_string_literal: true

require_relative "exa/version"

module Exa
  class Error < StandardError; end

  # Module-level configuration
  class << self
    attr_accessor :api_key, :base_url, :timeout

    def configure
      yield self
    end

    def reset
      self.api_key = nil
      self.base_url = DEFAULT_BASE_URL
      self.timeout = DEFAULT_TIMEOUT
    end
  end

  # Constants for default values
  DEFAULT_BASE_URL = "https://api.exa.ai"
  DEFAULT_TIMEOUT = 30

  # Set defaults
  self.base_url = DEFAULT_BASE_URL
  self.timeout = DEFAULT_TIMEOUT
end
