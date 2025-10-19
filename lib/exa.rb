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
      self.base_url = nil
      self.timeout = nil
    end
  end

  # Set defaults
  self.base_url = "https://api.exa.ai"
  self.timeout = 30
end
