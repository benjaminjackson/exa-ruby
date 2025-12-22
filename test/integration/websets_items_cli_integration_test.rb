# frozen_string_literal: true

require "test_helper"
require "json"
require "open3"

# Integration tests for webset-item-list CLI command
# Tests the actual CLI executable with real API calls
#
# NOTE: These tests make REAL API calls and cannot use VCR because VCR cannot
# intercept HTTP calls from external processes (CLI commands run via Open3).
#
# To run these tests:
# 1. Set EXA_API_KEY environment variable
# 2. Run: bundle exec rake test TEST=test/integration/websets_items_cli_integration_test.rb
#
# Tests are skipped in CI unless RUN_CLI_INTEGRATION_TESTS=true is set.
class WebsetsItemsCLIIntegrationTest < Minitest::Test
  include WebsetsCleanupHelper

  def skip_unless_cli_integration_enabled
    skip "Set RUN_CLI_INTEGRATION_TESTS=true to run CLI integration tests" unless ENV["RUN_CLI_INTEGRATION_TESTS"] == "true"
  end

  def setup
    super

    # Check for API key before proceeding with CLI integration tests
    if ENV["RUN_CLI_INTEGRATION_TESTS"] == "true"
      if ENV["EXA_API_KEY"].nil? || ENV["EXA_API_KEY"].empty?
        flunk "EXA_API_KEY environment variable must be set to run CLI integration tests. " \
              "Set it with: export EXA_API_KEY=your_api_key"
      end
    end

    @api_key = ENV.fetch("EXA_API_KEY", "test_key_for_vcr")
    ENV["EXA_API_KEY"] = @api_key
  end

  def teardown
    super
    Exa.reset
  end

  # Helper to run a CLI command and return stdout, stderr, and status
  def run_command(command)
    stdout, stderr, status = Open3.capture3(command)
    [stdout, stderr, status]
  end

  # Helper to parse JSON output from a command
  def parse_json_output(stdout)
    return {} if stdout.nil? || stdout.strip.empty?
    JSON.parse(stdout)
  rescue JSON::ParserError => e
    puts "Failed to parse JSON: #{stdout.inspect}"
    raise
  end

  # Helper to create a webset with items for testing
  def create_webset_with_items(count:)
    client = Exa::Client.new(api_key: @api_key)
    webset = client.create_webset(search: {
      query: "venture-backed technology startups",
      count: count
    })

    track_webset(webset.id)

    # Wait for webset to complete
    completed = wait_for_webset_completion(client, webset.id, timeout: 120)
    skip "Webset did not complete in time" unless completed&.idle?

    webset.id
  end

  # Test 5: Help text shows pagination options
  def test_help_text_shows_pagination_options
    command = "bundle exec exe/exa-ai-webset-item-list --help"
    stdout, _stderr, status = run_command(command)

    assert status.success?, "Help command should succeed"
    assert_includes stdout, "--limit N", "Help should document --limit flag"
    assert_includes stdout, "--cursor CURSOR", "Help should document --cursor flag"
    assert_includes stdout, "pagination", "Help should mention pagination"
    assert_includes stdout, "nextCursor", "Help should reference nextCursor"
  end

  # Test 1: Basic item listing (smoke test)
  def test_basic_item_listing
    skip_unless_cli_integration_enabled

    webset_id = create_webset_with_items(count: 3)

    command = "bundle exec exe/exa-ai-webset-item-list #{webset_id} --output-format json"
    stdout, stderr, status = run_command(command)

    skip "webset-item-list failed: #{stderr}" unless status.success?

    result = parse_json_output(stdout)

    # Verify structure (using snake_case keys from Ruby)
    assert result.key?("data"), "Response should have 'data' field"
    assert result.key?("has_more"), "Response should have 'has_more' field"
    assert result.key?("next_cursor"), "Response should have 'next_cursor' field"

    # Verify data
    assert result["data"].is_a?(Array), "data should be an array"
    refute_empty result["data"], "data should contain items"

    # Verify items have expected structure
    first_item = result["data"].first
    assert first_item.key?("id"), "Items should have 'id' field"
  end

  # Test 3: Cursor-based pagination (critical test)
  def test_cursor_based_pagination
    skip_unless_cli_integration_enabled

    webset_id = create_webset_with_items(count: 5)

    # First page with limit
    command1 = "bundle exec exe/exa-ai-webset-item-list #{webset_id} --limit 2 --output-format json"
    stdout1, stderr1, status1 = run_command(command1)

    skip "First page request failed: #{stderr1}" unless status1.success?

    result1 = parse_json_output(stdout1)

    # Verify pagination is available (using snake_case keys)
    skip "No pagination available (has_more is false)" unless result1["has_more"]
    skip "No next_cursor returned" if result1["next_cursor"].nil?

    # Verify first page
    assert result1["data"].is_a?(Array), "First page data should be an array"
    assert result1["data"].length <= 2, "First page should respect limit of 2"
    assert result1["has_more"], "has_more should be true when more items exist"
    refute_nil result1["next_cursor"], "next_cursor should be present when has_more is true"

    # Get first page item IDs
    first_page_ids = result1["data"].map { |item| item["id"] }

    # Second page with cursor
    cursor = result1["next_cursor"]
    command2 = "bundle exec exe/exa-ai-webset-item-list #{webset_id} --limit 2 --cursor '#{cursor}' --output-format json"
    stdout2, stderr2, status2 = run_command(command2)

    skip "Second page request failed: #{stderr2}" unless status2.success?

    result2 = parse_json_output(stdout2)

    # Verify second page
    assert result2["data"].is_a?(Array), "Second page data should be an array"
    refute_empty result2["data"], "Second page should contain items"

    # Get second page item IDs
    second_page_ids = result2["data"].map { |item| item["id"] }

    # Verify pages have different items
    assert_empty (first_page_ids & second_page_ids), "Pages should have different items (no overlap)"
  end
end
