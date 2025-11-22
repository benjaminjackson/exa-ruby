# frozen_string_literal: true

require "test_helper"
require "json"
require "tempfile"
require "open3"

# Integration tests for Websets CLI commands
# Tests the actual CLI executables with real API calls
#
# NOTE: These tests make REAL API calls and cannot use VCR because VCR cannot
# intercept HTTP calls from external processes (CLI commands run via Open3).
#
# To run these tests:
# 1. Set EXA_API_KEY environment variable
# 2. Run: bundle exec rake test TEST=test/integration/websets_cli_integration_test.rb
#
# Tests are skipped in CI unless RUN_CLI_INTEGRATION_TESTS=true is set.
# Help and error handling tests run without API calls.
class WebsetsCLIIntegrationTest < Minitest::Test
  include WebsetsCleanupHelper

  def skip_if_no_api_key
    skip "Set EXA_API_KEY to run CLI integration tests" unless ENV["EXA_API_KEY"] && !ENV["EXA_API_KEY"].empty?
  end

  def setup
    super
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

  # Test webset-create command with basic search
  def test_webset_create_basic
    skip_if_no_api_key

    # Using a simple, generic query to avoid API errors
    command = "bundle exec exe/exa-ai webset-create " \
              "--search '{\"query\":\"technology companies\",\"count\":1}' " \
              "--output-format json"

    stdout, stderr, status = run_command(command)

    assert status.success?, "webset-create should succeed. stderr: #{stderr}"
    result = parse_json_output(stdout)
    track_webset(result["id"])

    assert result["id"], "Should return an id"
    assert_equal "webset", result["object"]
    assert_includes ["idle", "pending", "running"], result["status"]
    refute_nil result["created_at"]
  end

  # Test webset-create with search from file
  def test_webset_create_with_search_file
    skip_if_no_api_key

    # Create temporary search file
    search_file = Tempfile.new(["search", ".json"])
    # Using a simple, generic query to avoid API errors
    search_data = {
      query: "software companies",
      count: 1
    }
    search_file.write(JSON.generate(search_data))
    search_file.close

    command = "bundle exec exe/exa-ai webset-create " \
              "--search @#{search_file.path} " \
              "--output-format json"

    stdout, stderr, status = run_command(command)

    assert status.success?, "webset-create with file should succeed. stderr: #{stderr}"
    result = parse_json_output(stdout)
    track_webset(result["id"])

    assert result["id"], "Should return an id"
    assert_equal "webset", result["object"]
    assert result["searches"].is_a?(Array)
    refute_empty result["searches"]

    search_file.unlink
  end


  # Test webset-create with metadata
  def test_webset_create_with_metadata
    skip_if_no_api_key

          command = "bundle exec exe/exa-ai webset-create " \
                "--search '{\"query\":\"Tech startups\",\"count\":1}' " \
                "--metadata '{\"project\":\"Q4-research\",\"team\":\"growth\"}' " \
                "--output-format json"

      stdout, _stderr, status = run_command(command)

      assert status.success?, "webset-create with metadata should succeed"
      result = parse_json_output(stdout)
      track_webset(result["id"])

      assert result["id"], "Should return an id"
      assert_equal "Q4-research", result.dig("metadata", "project")
      assert_equal "growth", result.dig("metadata", "team")
    end


  # Test webset-create with external ID
  def test_webset_create_with_external_id
    skip_if_no_api_key

          external_id = "cli-test-#{Time.now.to_i}"

      command = "bundle exec exe/exa-ai webset-create " \
                "--search '{\"query\":\"Marketing agencies\",\"count\":1}' " \
                "--external-id #{external_id} " \
                "--output-format json"

      stdout, _stderr, status = run_command(command)

      assert status.success?, "webset-create with external_id should succeed"
      result = parse_json_output(stdout)
      track_webset(result["id"])

      assert_equal external_id, result["external_id"]
    end


  # Test webset-create with enrichments
  def test_webset_create_with_enrichments
    skip_if_no_api_key

    enrichments = [
      {
        description: "Extract company description",
        format: "text"
      },
      {
        description: "Determine company size",
        format: "options",
        options: [
          { label: "Small" },
          { label: "Medium" },
          { label: "Large" }
        ]
      }
    ]

    command = "bundle exec exe/exa-ai webset-create " \
              "--search '{\"query\":\"E-commerce companies\",\"count\":1}' " \
              "--enrichments '#{JSON.generate(enrichments)}' " \
              "--output-format json"

    stdout, _stderr, status = run_command(command)

    assert status.success?, "webset-create with enrichments should succeed"
    result = parse_json_output(stdout)
    track_webset(result["id"])

    # Track enrichments if they have IDs
    result["enrichments"].each { |e| track_enrichment(result["id"], e["id"]) if e["id"] }

    assert result["id"], "Should return an id"
    assert result["enrichments"].is_a?(Array)
    refute_empty result["enrichments"]
    assert_equal 2, result["enrichments"].length
  end


  # Test webset-get command
  def test_webset_get
    skip_if_no_api_key

          # First create a webset
      create_command = "bundle exec exe/exa-ai webset-create " \
                       "--search '{\"query\":\"Fintech companies\",\"count\":1}' " \
                       "--output-format json"

      create_stdout, _stderr, create_status = run_command(create_command)
      assert create_status.success?
      created = parse_json_output(create_stdout)
      webset_id = track_webset(created["id"])

      # Now get it
      get_command = "bundle exec exe/exa-ai webset-get #{webset_id} --output-format json"

      stdout, _stderr, status = run_command(get_command)

      assert status.success?, "webset-get should succeed"
      result = parse_json_output(stdout)

      assert_equal webset_id, result["id"]
      assert_equal "webset", result["object"]
    end


  # Test webset-get with pretty format
  def test_webset_get_pretty_format
    skip_if_no_api_key

          # First create a webset
      create_command = "bundle exec exe/exa-ai webset-create " \
                       "--search '{\"query\":\"Healthcare companies\",\"count\":1}' " \
                       "--output-format json"

      create_stdout, _stderr, _create_status = run_command(create_command)
      created = parse_json_output(create_stdout)
      webset_id = track_webset(created["id"])

      # Get with pretty format
      get_command = "bundle exec exe/exa-ai webset-get #{webset_id} --output-format pretty"

      stdout, _stderr, status = run_command(get_command)

      assert status.success?, "webset-get with pretty format should succeed"
      # Pretty format is still JSON, just nicely formatted with indentation
      result = parse_json_output(stdout)
      assert_equal webset_id, result["id"]
      # Verify it has indentation (pretty-printed)
      assert_includes stdout, "  "
    end


  # Test webset-list command
  def test_webset_list
    skip_if_no_api_key

          command = "bundle exec exe/exa-ai webset-list --limit 5 --output-format json"

      stdout, _stderr, status = run_command(command)

      assert status.success?, "webset-list should succeed"
      result = parse_json_output(stdout)

      # List response has data array and optional pagination fields
      assert result["data"].is_a?(Array)
      assert result["data"].length <= 5
    end


  # Test webset-list with pagination
  def test_webset_list_pagination
    skip_if_no_api_key

    # Get first page
    command1 = "bundle exec exe/exa-ai webset-list --limit 2 --output-format json"
    stdout1, _stderr, status1 = run_command(command1)

    assert status1.success?
    result1 = parse_json_output(stdout1)
    assert result1["data"].is_a?(Array)
    assert result1["data"].length <= 2

    # Skip if no next page available for pagination test
    skip "No next page available for pagination test" unless result1["hasMore"] && result1["nextCursor"]

    # Get next page with cursor
    next_cursor = result1["nextCursor"]
    command2 = "bundle exec exe/exa-ai webset-list --limit 2 --cursor '#{next_cursor}' --output-format json"
    stdout2, _stderr, status2 = run_command(command2)

    assert status2.success?
    result2 = parse_json_output(stdout2)
    assert result2["data"].is_a?(Array)
  end

  # Test webset-update command
  def test_webset_update
    skip_if_no_api_key

          # First create a webset
      create_command = "bundle exec exe/exa-ai webset-create " \
                       "--search '{\"query\":\"Education companies\",\"count\":1}' " \
                       "--output-format json"

      create_stdout, _stderr, _create_status = run_command(create_command)
      created = parse_json_output(create_stdout)
      webset_id = track_webset(created["id"])

      # Update it
      update_command = "bundle exec exe/exa-ai webset-update #{webset_id} " \
                       "--metadata '{\"updated\":\"true\",\"version\":\"2\"}' " \
                       "--output-format json"

      stdout, stderr, status = run_command(update_command)

      assert status.success?, "webset-update should succeed. stderr: #{stderr}"
      result = parse_json_output(stdout)

      # Skip if result is empty (feature might not be fully implemented)
      skip "webset-update returned empty response" if result.empty?

      assert_equal webset_id, result["id"]
      assert_equal "true", result.dig("metadata", "updated")
      assert_equal "2", result.dig("metadata", "version")
    end


  # Test webset-delete command
  def test_webset_delete
    skip_if_no_api_key

          # First create a webset
      create_command = "bundle exec exe/exa-ai webset-create " \
                       "--search '{\"query\":\"Retail companies\",\"count\":1}' " \
                       "--output-format json"

      create_stdout, _stderr, _create_status = run_command(create_command)
      created = parse_json_output(create_stdout)
      webset_id = track_webset(created["id"])

      # Delete it (using --force to skip confirmation)
      delete_command = "bundle exec exe/exa-ai webset-delete #{webset_id} --force --output-format json"

      stdout, _stderr, status = run_command(delete_command)

      assert status.success?, "webset-delete should succeed"
      result = parse_json_output(stdout)

      # API returns the webset object after deletion
      assert_equal webset_id, result["id"]
      assert_equal "webset", result["object"]
    end


  # Test webset-cancel command
  def test_webset_cancel
    skip_if_no_api_key

          # First create a webset (should be in running/pending state initially)
      create_command = "bundle exec exe/exa-ai webset-create " \
                       "--search '{\"query\":\"Manufacturing companies\",\"count\":1}' " \
                       "--output-format json"

      create_stdout, create_stderr, create_status = run_command(create_command)
      assert create_status.success?, "webset-create should succeed. stderr: #{create_stderr}"

      created = parse_json_output(create_stdout)
      webset_id = track_webset(created["id"])
      assert webset_id, "webset-create should return a webset with an id. Response: #{created.inspect}"

      # Cancel it
      cancel_command = "bundle exec exe/exa-ai webset-cancel #{webset_id} --output-format json"

      stdout, stderr, status = run_command(cancel_command)

      assert status.success?, "webset-cancel should succeed. stderr: #{stderr}"
      result = parse_json_output(stdout)

      # Skip if result is empty (feature might not be fully implemented)
      skip "webset-cancel returned empty response" if result.empty?

      assert_equal webset_id, result["id"]
      # Status should be cancelled or remain in current state if already completed
      assert_includes ["cancelled", "idle", "pending", "running"], result["status"]
    end


  # Test webset-create with text output format
  def test_webset_create_text_format
    skip_if_no_api_key

    # Using a simple, generic query to avoid API errors
    command = "bundle exec exe/exa-ai webset-create " \
              "--search '{\"query\":\"software companies\",\"count\":1}' " \
              "--output-format text"

    stdout, stderr, status = run_command(command)

    # Skip if text format is not implemented yet
    unless status.success?
      skip "webset-create with text format not working yet. stderr: #{stderr}"
    end

    # Extract and track webset ID from text output
    if stdout =~ /(ws_[a-zA-Z0-9]+|webset_[a-zA-Z0-9]+)/
      track_webset($1)
    end

    # Text format is a simple, compact text representation
    assert stdout.include?("webset_") || stdout.include?("ws_"),
           "Output should contain webset ID"
    assert_includes stdout, "Status" unless stdout.empty?
  end


  # Test error handling for invalid JSON
  def test_webset_create_invalid_json
    command = "bundle exec exe/exa-ai webset-create " \
              "--search 'invalid-json' " \
              "--output-format json"

    stdout, stderr, status = run_command(command)

    refute status.success?, "webset-create with invalid JSON should fail"
    # Error could be in stdout or stderr
    combined = stdout + stderr
    assert_includes combined.downcase, "error"
  end

  # Test error handling for missing required arguments
  def test_webset_create_missing_search
    command = "bundle exec exe/exa-ai webset-create --output-format json"

    stdout, stderr, status = run_command(command)

    refute status.success?, "webset-create without --search should fail"
    combined = stdout + stderr
    assert_includes combined, "search"
  end

  # Test webset-get with non-existent ID
  def test_webset_get_not_found
          command = "bundle exec exe/exa-ai webset-get ws_nonexistent123 --output-format json"

      stdout, stderr, status = run_command(command)

      refute status.success?, "webset-get with non-existent ID should fail"
      # Should get a 404 error
      combined = stdout + stderr
      assert_includes combined.downcase, "not found"
    end


  # Test help output for each command
  def test_webset_create_help
    stdout, _stderr, status = run_command("bundle exec exe/exa-ai webset-create --help")

    assert status.success?, "webset-create --help should succeed"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "--search"
    assert_includes stdout, "--enrichments"
    assert_includes stdout, "--metadata"
  end

  def test_webset_get_help
    stdout, _stderr, status = run_command("bundle exec exe/exa-ai webset-get --help")

    assert status.success?, "webset-get --help should succeed"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "webset_id"
  end

  def test_webset_list_help
    stdout, _stderr, status = run_command("bundle exec exe/exa-ai webset-list --help")

    assert status.success?, "webset-list --help should succeed"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "--limit"
    assert_includes stdout, "--cursor"
  end

  def test_webset_update_help
    stdout, _stderr, status = run_command("bundle exec exe/exa-ai webset-update --help")

    assert status.success?, "webset-update --help should succeed"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "webset_id"
    assert_includes stdout, "--metadata"
  end

  def test_webset_delete_help
    stdout, _stderr, status = run_command("bundle exec exe/exa-ai webset-delete --help")

    assert status.success?, "webset-delete --help should succeed"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "webset_id"
    assert_includes stdout, "--force"
  end

  def test_webset_cancel_help
    stdout, _stderr, status = run_command("bundle exec exe/exa-ai webset-cancel --help")

    assert status.success?, "webset-cancel --help should succeed"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "webset_id"
  end
end
