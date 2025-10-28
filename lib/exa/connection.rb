# frozen_string_literal: true

require "faraday"
require "logger"

module Exa
  class Connection
    DEFAULT_BASE_URL = "https://api.exa.ai"
    def self.build(api_key:, **options, &block)
      Faraday.new(url: options[:base_url] || DEFAULT_BASE_URL) do |conn|
        # Authentication
        conn.headers["x-api-key"] = api_key

        # Request/Response JSON encoding
        conn.request :json

        # Debug logging (when enabled via option)
        if options[:debug]
          conn.response :logger, Logger.new($stdout), headers: true, bodies: true
        end

        # Custom error handling (registered before JSON so it runs after in response chain)
        conn.response :raise_error
        conn.response :json, content_type: /\bjson$/

        # Timeouts
        conn.options.timeout = options[:timeout] || 30
        conn.options.open_timeout = options[:open_timeout] || 10

        # Adapter (allow override for testing)
        if block_given?
          conn.adapter options[:adapter] || Faraday.default_adapter, &block
        else
          conn.adapter options[:adapter] || Faraday.default_adapter
        end
      end
    end
  end
end
