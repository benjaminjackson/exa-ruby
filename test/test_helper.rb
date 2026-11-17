# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Load environment variables from .env file if dotenv is available
begin
  require "dotenv"
  Dotenv.load
rescue LoadError
  # dotenv not available, skip loading .env file
end

require "exa-ai"
require "toon"
require "minitest/autorun"
require "minitest/fail_fast"
require "webmock/minitest"
require "vcr"

# Check for required environment variables and provide fallback for VCR playback
unless ENV["EXA_API_KEY"]
  warn "WARNING: EXA_API_KEY environment variable is not set."
  warn "Using test key for VCR playback. To record new cassettes, set: export EXA_API_KEY=your_api_key"
  # Provide a default API key for VCR playback when not set
  # This value is never used for real API calls - VCR replays from cassettes
  # and WebMock blocks network connections
  ENV["EXA_API_KEY"] = "test_key_for_vcr_playback"
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
  # Integration runs may make real requests outside cassette blocks. In every
  # other run, a request that matches no stub and no cassette must raise, never
  # reach the network.
  config.allow_http_connections_when_no_cassette = ENV["RUN_INTEGRATION_TESTS"] == "true"
  # Filter sensitive data
  config.filter_sensitive_data("<EXA_API_KEY>") { ENV["EXA_API_KEY"] }

  # Disable debug logging during VCR recording to prevent logger output
  # from contaminating cassettes
  config.before_record do |interaction|
    @vcr_debug_state = ENV.delete("EXA_DEBUG")
  end

  config.after_http_request do |request, response|
    ENV["EXA_DEBUG"] = @vcr_debug_state if @vcr_debug_state
  end
end

# Disable external network connections in tests (VCR will manage allowed connections)
WebMock.disable_net_connect!(allow_localhost: true)

# Skip integration tests unless RUN_INTEGRATION_TESTS flag is set
# This prevents accidental API calls during development
def skip_unless_integration_enabled
  skip "Set RUN_INTEGRATION_TESTS=true to run integration tests (VCR-based)" unless ENV["RUN_INTEGRATION_TESTS"] == "true"
end

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

# Lists every key in a parsed JSON request body that still has an
# underscore, skipping the subtrees that hold user data and keep their keys.
module RequestBodyKeys
  def snake_case_keys(value)
    case value
    when Hash
      value.flat_map do |key, nested|
        own = key.to_s.include?("_") ? [key.to_s] : []
        Exa::Services::ParameterConverter::PROTECTED_KEYS.include?(key.to_s) ? own : own + snake_case_keys(nested)
      end
    when Array
      value.flat_map { |element| snake_case_keys(element) }
    else
      []
    end
  end
end

Minitest::Test.include(RequestBodyKeys)

# Runs an executable from exe/ inside the test process, so WebMock stubs
# apply to its requests, and returns [stdout, stderr, exit_status]. The exit
# status is nil when the script does not call exit. The second argument to
# load wraps the script's top-level methods in an anonymous module, so they
# do not leak onto Object.
def run_exe_in_process(name, *argv)
  original_argv = ARGV.dup
  ARGV.replace(argv)
  exit_status = nil
  stdout, stderr = capture_io do
    load File.expand_path("../exe/#{name}", __dir__), true
  rescue SystemExit => e
    exit_status = e.status
  end
  [stdout, stderr, exit_status]
ensure
  ARGV.replace(original_argv)
end
