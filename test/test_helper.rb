# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "exa-ai"
require "minitest/autorun"
require "webmock/minitest"
require "vcr"

# Configure VCR for integration tests
# VCR works with WebMock to record/replay HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
  # Filter sensitive data
  config.filter_sensitive_data("<EXA_API_KEY>") { ENV["EXA_API_KEY"] }
end

# Disable external network connections in tests (VCR will manage allowed connections)
WebMock.disable_net_connect!(allow_localhost: true)
