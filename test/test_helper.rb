# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "exa-ai"
require "minitest/autorun"
require "minitest/fail_fast"
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
  # Allow HTTP connections when no cassette is active (for polling outside cassette blocks)
  config.allow_http_connections_when_no_cassette = true
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
# When replaying cassettes, this will be called but skip polling since cassettes
# already contain the final state and the polling requests won't be recorded
def wait_for_webset_completion(client, webset_id, timeout: 120, interval: 2)
  start_time = Time.now
  max_attempts = (timeout / interval).to_i
  attempts = 0

  loop do
    begin
      webset = client.get_webset(webset_id)

      # Webset is complete when status is "idle"
      return webset if webset.idle?
    rescue => e
      # If we get an error (e.g., unmatched request during cassette playback,
      # connection refused, or other network error), just return nil and let
      # the test continue. This is expected when replaying cassettes that don't
      # contain polling requests.
      if e.message.include?("NetConnectNotAllowedError") || e.message.include?("Connection refused")
        return nil
      end
      # Re-raise other unexpected errors
      raise
    end

    # Check if we've exceeded the timeout
    if Time.now - start_time > timeout || attempts > max_attempts
      raise "Webset #{webset_id} did not complete within #{timeout} seconds. Current status: #{webset.status rescue 'unknown'}"
    end

    # Wait before polling again
    sleep interval
    attempts += 1
  end
end

# Module for automatic cleanup of Websets resources created during tests
# Include this module in integration tests that create websets, searches, or enrichments
# to ensure all created resources are properly cleaned up after each test.
module WebsetsCleanupHelper
  require "open3"

  def setup
    super
    @created_websets = []
    @created_searches = []
    @created_enrichments = []
  end

  def teardown
    cleanup_resources
    super
  end

  # Track a created webset for cleanup
  def track_webset(webset_id)
    @created_websets << webset_id
    webset_id
  end

  # Track a created search for cleanup
  def track_search(webset_id, search_id)
    @created_searches << [webset_id, search_id]
    search_id
  end

  # Track a created enrichment for cleanup
  def track_enrichment(webset_id, enrichment_id)
    @created_enrichments << [webset_id, enrichment_id]
    enrichment_id
  end

  private

  # Clean up all tracked resources in the correct dependency order
  def cleanup_resources
    # Only cleanup if we have a real API key (not using VCR cassettes)
    return unless should_cleanup?

    # Clean up enrichments first (they depend on websets)
    cleanup_enrichments

    # Then clean up searches (they also depend on websets)
    cleanup_searches

    # Finally clean up websets
    cleanup_websets
  end

  # Check if we should perform cleanup
  # Only cleanup when using a real API key (not VCR placeholder)
  def should_cleanup?
    @api_key && @api_key != "test_key_for_vcr"
  end

  def cleanup_enrichments
    @created_enrichments.each do |webset_id, enrichment_id|
      delete_enrichment(webset_id, enrichment_id)
    rescue => e
      # Ignore errors during cleanup
    end
  end

  def cleanup_searches
    @created_searches.each do |webset_id, search_id|
      delete_search(webset_id, search_id)
    rescue => e
      # Ignore errors during cleanup
    end
  end

  def cleanup_websets
    @created_websets.each do |webset_id|
      delete_webset(webset_id)
    rescue => e
      # Ignore errors during cleanup
    end
  end

  # Delete an enrichment - supports both client and CLI approaches
  def delete_enrichment(webset_id, enrichment_id)
    if use_cli_cleanup?
      run_cli_command("bundle exec exe/exa-ai enrichment-delete #{webset_id} #{enrichment_id} --force")
    else
      get_client.delete_enrichment(webset_id: webset_id, id: enrichment_id)
    end
  end

  # Delete a search - supports both client and CLI approaches
  def delete_search(webset_id, search_id)
    if use_cli_cleanup?
      run_cli_command("bundle exec exe/exa-ai search-delete #{webset_id} #{search_id} --force")
    else
      # Client-based search deletion (cancel the search)
      get_client.cancel_webset_search(webset_id: webset_id, id: search_id)
    end
  end

  # Delete a webset - supports both client and CLI approaches
  def delete_webset(webset_id)
    if use_cli_cleanup?
      run_cli_command("bundle exec exe/exa-ai webset-delete #{webset_id} --force")
    else
      get_client.delete_webset(webset_id)
    end
  end

  # Check if we should use CLI-based cleanup
  # CLI tests define a run_command method, so we use that as the indicator
  def use_cli_cleanup?
    respond_to?(:run_command, true)
  end

  # Get or create a client for cleanup
  def get_client
    @cleanup_client ||= Exa::Client.new(api_key: @api_key)
  end

  # Run a CLI command for cleanup
  def run_cli_command(command)
    stdout, stderr, status = Open3.capture3(command)
    [stdout, stderr, status]
  end
end
