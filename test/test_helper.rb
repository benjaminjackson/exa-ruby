# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "exa-ai"
require "minitest/autorun"
require "webmock/minitest"
require "vcr"

# Check for required environment variables
unless ENV["EXA_API_KEY"]
  warn "WARNING: EXA_API_KEY environment variable is not set. Integration tests will fail."
  warn "Set it with: export EXA_API_KEY=your_api_key"
end

# Configure VCR for integration tests
# VCR works with WebMock to record/replay HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body],
    allow_playback_repeats: true
  }
  # Filter sensitive data
  config.filter_sensitive_data("<EXA_API_KEY>") { ENV["EXA_API_KEY"] }
end

# Disable external network connections in tests (VCR will manage allowed connections)
WebMock.disable_net_connect!(allow_localhost: true)

# Debug logging helper
def with_debug_logging
  original_debug = ENV["EXA_DEBUG"]
  ENV["EXA_DEBUG"] = "true"
  yield
ensure
  original_debug ? (ENV["EXA_DEBUG"] = original_debug) : ENV.delete("EXA_DEBUG")
end

# API key helper for tests that need to temporarily set ENV["EXA_API_KEY"]
def with_api_key(api_key)
  original = ENV["EXA_API_KEY"]
  ENV["EXA_API_KEY"] = api_key
  yield
ensure
  original ? (ENV["EXA_API_KEY"] = original) : ENV.delete("EXA_API_KEY")
end

# Poll a webset until it reaches idle status or times out
# This prevents rate limiting issues when running multiple webset creation tests
def wait_for_webset_completion(client, webset_id, timeout: 120, interval: 2)
  start_time = Time.now

  loop do
    webset = client.get_webset(webset_id)

    # Webset is complete when status is "idle"
    return webset if webset.idle?

    # Check if we've exceeded the timeout
    if Time.now - start_time > timeout
      raise "Webset #{webset_id} did not complete within #{timeout} seconds. Current status: #{webset.status}"
    end

    # Wait before polling again
    sleep interval
  end
end
