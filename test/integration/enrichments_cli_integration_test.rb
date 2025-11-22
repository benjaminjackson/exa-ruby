# frozen_string_literal: true

require "test_helper"
require "json"
require "tempfile"
require "open3"

# Integration tests for Enrichments CLI commands
# Tests the actual CLI executables with VCR for API interactions
#
# NOTE: VCR cassettes for CLI commands must be recorded manually because VCR
# cannot intercept HTTP calls from external processes (CLI commands run via Open3).
#
# To record cassettes:
# 1. Set EXA_API_KEY environment variable
# 2. Delete the cassette file you want to re-record from test/vcr_cassettes/
# 3. Run the test - it will make a real API call and record the cassette
# 4. The cassette will be used for subsequent test runs
#
# Some tests (help, error handling) don't require cassettes and will always pass.
class EnrichmentsCLIIntegrationTest < Minitest::Test
  def setup
    @api_key = ENV.fetch("EXA_API_KEY", "test_key_for_vcr")
    ENV["EXA_API_KEY"] = @api_key
  end

  def teardown
    Exa.reset
  end

  # Helper to run a CLI command and return stdout, stderr, and status
  def run_command(command)
    stdout, stderr, status = Open3.capture3(command)
    [stdout, stderr, status]
  end

  # Helper to parse JSON output from a command
  def parse_json_output(stdout)
    JSON.parse(stdout)
  end

  # Test enrichment-create command with basic text format
  def test_enrichment_create_text_format
    VCR.use_cassette("cli_enrichment_create_text") do
      # First create a webset
      create_ws_cmd = "bundle exec exe/exa-ai webset-create " \
                      "--search '{\"query\":\"Tech companies\",\"count\":1}' " \
                      "--output-format json"
      ws_stdout, _stderr, _status = run_command(create_ws_cmd)
      webset = parse_json_output(ws_stdout)
      webset_id = webset["id"]

      # Create enrichment
      command = "bundle exec exe/exa-ai enrichment-create #{webset_id} " \
                "--description 'Find company email' " \
                "--format text " \
                "--output-format json"

      stdout, _stderr, status = run_command(command)

      assert status.success?, "enrichment-create should succeed"
      result = parse_json_output(stdout)

      assert_includes result["id"], "enrich_"
      assert_equal "webset_enrichment", result["object"]
      assert_equal "text", result["format"]
    end
  end

  # Test enrichment-create with email format
  def test_enrichment_create_email_format
    VCR.use_cassette("cli_enrichment_create_email") do
      # First create a webset
      create_ws_cmd = "bundle exec exe/exa-ai webset-create " \
                      "--search '{\"query\":\"SaaS companies\",\"count\":1}' " \
                      "--output-format json"
      ws_stdout, _stderr, _status = run_command(create_ws_cmd)
      webset = parse_json_output(ws_stdout)
      webset_id = webset["id"]

      # Create enrichment with email format
      command = "bundle exec exe/exa-ai enrichment-create #{webset_id} " \
                "--description 'Extract contact email' " \
                "--format email " \
                "--output-format json"

      stdout, _stderr, status = run_command(command)

      assert status.success?, "enrichment-create with email format should succeed"
      result = parse_json_output(stdout)

      assert_equal "email", result["format"]
    end
  end

  # Test enrichment-create with options format
  def test_enrichment_create_options_format
    VCR.use_cassette("cli_enrichment_create_options") do
      # First create a webset
      create_ws_cmd = "bundle exec exe/exa-ai webset-create " \
                      "--search '{\"query\":\"Startups\",\"count\":1}' " \
                      "--output-format json"
      ws_stdout, _stderr, _status = run_command(create_ws_cmd)
      webset = parse_json_output(ws_stdout)
      webset_id = webset["id"]

      # Create enrichment with options format
      options = [
        { label: "Small (1-10)" },
        { label: "Medium (11-50)" },
        { label: "Large (51+)" }
      ]

      command = "bundle exec exe/exa-ai enrichment-create #{webset_id} " \
                "--description 'Company size category' " \
                "--format options " \
                "--options '#{JSON.generate(options)}' " \
                "--output-format json"

      stdout, _stderr, status = run_command(command)

      assert status.success?, "enrichment-create with options should succeed"
      result = parse_json_output(stdout)

      assert_equal "options", result["format"]
      assert_equal 3, result["options"].length
    end
  end

  # Test enrichment-create with options from file
  def test_enrichment_create_options_from_file
    VCR.use_cassette("cli_enrichment_create_options_file") do
      # First create a webset
      create_ws_cmd = "bundle exec exe/exa-ai webset-create " \
                      "--search '{\"query\":\"E-commerce companies\",\"count\":1}' " \
                      "--output-format json"
      ws_stdout, _stderr, _status = run_command(create_ws_cmd)
      webset = parse_json_output(ws_stdout)
      webset_id = webset["id"]

      # Create temporary options file
      options_file = Tempfile.new(["options", ".json"])
      options = [
        { label: "Yes" },
        { label: "No" },
        { label: "Unknown" }
      ]
      options_file.write(JSON.generate(options))
      options_file.close

      # Create enrichment with options from file
      command = "bundle exec exe/exa-ai enrichment-create #{webset_id} " \
                "--description 'Has mobile app?' " \
                "--format options " \
                "--options @#{options_file.path} " \
                "--output-format json"

      stdout, _stderr, status = run_command(command)

      assert status.success?, "enrichment-create with options file should succeed"
      result = parse_json_output(stdout)

      assert_equal "options", result["format"]
      assert_equal 3, result["options"].length

      options_file.unlink
    end
  end

  # Test enrichment-get command
  def test_enrichment_get
    VCR.use_cassette("cli_enrichment_get") do
      # First create a webset and enrichment
      create_ws_cmd = "bundle exec exe/exa-ai webset-create " \
                      "--search '{\"query\":\"Healthcare companies\",\"count\":1}' " \
                      "--output-format json"
      ws_stdout, _stderr, _status = run_command(create_ws_cmd)
      webset = parse_json_output(ws_stdout)
      webset_id = webset["id"]

      create_enrich_cmd = "bundle exec exe/exa-ai enrichment-create #{webset_id} " \
                          "--description 'Find phone number' " \
                          "--format text " \
                          "--output-format json"
      enrich_stdout, _stderr, _status = run_command(create_enrich_cmd)
      enrichment = parse_json_output(enrich_stdout)
      enrichment_id = enrichment["id"]

      # Get the enrichment
      command = "bundle exec exe/exa-ai enrichment-get #{webset_id} #{enrichment_id} --output-format json"

      stdout, _stderr, status = run_command(command)

      assert status.success?, "enrichment-get should succeed"
      result = parse_json_output(stdout)

      assert_equal enrichment_id, result["id"]
      assert_equal "webset_enrichment", result["object"]
    end
  end

  # Test enrichment-list command
  def test_enrichment_list
    VCR.use_cassette("cli_enrichment_list") do
      # First create a webset with enrichments
      create_ws_cmd = "bundle exec exe/exa-ai webset-create " \
                      "--search '{\"query\":\"Fintech companies\",\"count\":1}' " \
                      "--output-format json"
      ws_stdout, _stderr, _status = run_command(create_ws_cmd)
      webset = parse_json_output(ws_stdout)
      webset_id = webset["id"]

      # Create an enrichment
      create_enrich_cmd = "bundle exec exe/exa-ai enrichment-create #{webset_id} " \
                          "--description 'Find headquarters location' " \
                          "--format text " \
                          "--output-format json"
      run_command(create_enrich_cmd)

      # List enrichments
      command = "bundle exec exe/exa-ai enrichment-list #{webset_id} --output-format json"

      stdout, _stderr, status = run_command(command)

      assert status.success?, "enrichment-list should succeed"
      result = parse_json_output(stdout)

      # List response has data array
      assert result["data"].is_a?(Array)
      refute_empty result["data"]
    end
  end

  # Test enrichment-update command
  def test_enrichment_update
    VCR.use_cassette("cli_enrichment_update") do
      # Create webset and enrichment
      create_ws_cmd = "bundle exec exe/exa-ai webset-create " \
                      "--search '{\"query\":\"Retail companies\",\"count\":1}' " \
                      "--output-format json"
      ws_stdout, _stderr, _status = run_command(create_ws_cmd)
      webset = parse_json_output(ws_stdout)
      webset_id = webset["id"]

      create_enrich_cmd = "bundle exec exe/exa-ai enrichment-create #{webset_id} " \
                          "--description 'Initial description' " \
                          "--format text " \
                          "--output-format json"
      enrich_stdout, _stderr, _status = run_command(create_enrich_cmd)
      enrichment = parse_json_output(enrich_stdout)
      enrichment_id = enrichment["id"]

      # Update the enrichment
      command = "bundle exec exe/exa-ai enrichment-update #{webset_id} #{enrichment_id} " \
                "--description 'Updated description' " \
                "--output-format json"

      stdout, _stderr, status = run_command(command)

      assert status.success?, "enrichment-update should succeed"
      result = parse_json_output(stdout)

      assert_equal enrichment_id, result["id"]
      assert_equal "Updated description", result["description"]
    end
  end

  # Test enrichment-delete command
  def test_enrichment_delete
    VCR.use_cassette("cli_enrichment_delete") do
      # Create webset and enrichment
      create_ws_cmd = "bundle exec exe/exa-ai webset-create " \
                      "--search '{\"query\":\"Manufacturing companies\",\"count\":1}' " \
                      "--output-format json"
      ws_stdout, _stderr, _status = run_command(create_ws_cmd)
      webset = parse_json_output(ws_stdout)
      webset_id = webset["id"]

      create_enrich_cmd = "bundle exec exe/exa-ai enrichment-create #{webset_id} " \
                          "--description 'To be deleted' " \
                          "--format text " \
                          "--output-format json"
      enrich_stdout, _stderr, _status = run_command(create_enrich_cmd)
      enrichment = parse_json_output(enrich_stdout)
      enrichment_id = enrichment["id"]

      # Delete the enrichment (with --force to skip confirmation)
      command = "bundle exec exe/exa-ai enrichment-delete #{webset_id} #{enrichment_id} " \
                "--force --output-format json"

      stdout, _stderr, status = run_command(command)

      assert status.success?, "enrichment-delete should succeed"
      result = parse_json_output(stdout)

      # API returns either "webset_enrichment.deleted" or just "webset_enrichment" with deleted: true
      assert_includes ["webset_enrichment.deleted", "webset_enrichment"], result["object"]
      assert_equal enrichment_id, result["id"]
      assert_equal true, result["deleted"]
    end
  end

  # Test enrichment-cancel command
  def test_enrichment_cancel
    VCR.use_cassette("cli_enrichment_cancel") do
      # Create webset and enrichment
      create_ws_cmd = "bundle exec exe/exa-ai webset-create " \
                      "--search '{\"query\":\"Education companies\",\"count\":1}' " \
                      "--output-format json"
      ws_stdout, _stderr, _status = run_command(create_ws_cmd)
      webset = parse_json_output(ws_stdout)
      webset_id = webset["id"]

      create_enrich_cmd = "bundle exec exe/exa-ai enrichment-create #{webset_id} " \
                          "--description 'To be cancelled' " \
                          "--format text " \
                          "--output-format json"
      enrich_stdout, _stderr, _status = run_command(create_enrich_cmd)
      enrichment = parse_json_output(enrich_stdout)
      enrichment_id = enrichment["id"]

      # Cancel the enrichment
      command = "bundle exec exe/exa-ai enrichment-cancel #{webset_id} #{enrichment_id} --output-format json"

      stdout, _stderr, status = run_command(command)

      assert status.success?, "enrichment-cancel should succeed"
      result = parse_json_output(stdout)

      assert_equal enrichment_id, result["id"]
      assert_includes ["cancelled", "idle", "pending", "running", "completed"], result["status"]
    end
  end

  # Test enrichment-create with pretty output
  def test_enrichment_create_pretty_format
    VCR.use_cassette("cli_enrichment_create_pretty") do
      # Create webset
      create_ws_cmd = "bundle exec exe/exa-ai webset-create " \
                      "--search '{\"query\":\"AI companies\",\"count\":1}' " \
                      "--output-format json"
      ws_stdout, _stderr, _status = run_command(create_ws_cmd)
      webset = parse_json_output(ws_stdout)
      webset_id = webset["id"]

      # Create enrichment with pretty format
      command = "bundle exec exe/exa-ai enrichment-create #{webset_id} " \
                "--description 'Find website URL' " \
                "--format url " \
                "--output-format pretty"

      stdout, _stderr, status = run_command(command)

      assert status.success?, "enrichment-create with pretty format should succeed"
      # Pretty format is still JSON, just nicely formatted
      result = parse_json_output(stdout)
      assert result["id"].start_with?("wenrich_") || result["id"].start_with?("enrich_")
      # Verify it has indentation (pretty-printed)
      assert_includes stdout, "  "
    end
  end

  # Test error handling for invalid format
  def test_enrichment_create_invalid_format
    command = "bundle exec exe/exa-ai enrichment-create ws_test " \
              "--description 'Test' " \
              "--format invalid_format " \
              "--output-format json"

    stdout, stderr, status = run_command(command)

    refute status.success?, "enrichment-create with invalid format should fail"
    combined = stdout + stderr
    assert_includes combined.downcase, "error"
  end

  # Test error handling for missing description
  def test_enrichment_create_missing_description
    command = "bundle exec exe/exa-ai enrichment-create ws_test " \
              "--format text " \
              "--output-format json"

    stdout, stderr, status = run_command(command)

    refute status.success?, "enrichment-create without description should fail"
    combined = stdout + stderr
    assert_includes combined, "description"
  end

  # Test error handling for options format without options
  def test_enrichment_create_options_without_options
    command = "bundle exec exe/exa-ai enrichment-create ws_test " \
              "--description 'Test' " \
              "--format options " \
              "--output-format json"

    stdout, stderr, status = run_command(command)

    refute status.success?, "enrichment-create with options format but no options should fail"
    combined = stdout + stderr
    assert_includes combined.downcase, "options"
  end

  # Test help output for each command
  def test_enrichment_create_help
    stdout, _stderr, status = run_command("bundle exec exe/exa-ai enrichment-create --help")

    assert status.success?, "enrichment-create --help should succeed"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "webset_id"
    assert_includes stdout, "--description"
    assert_includes stdout, "--format"
    assert_includes stdout, "--options"
  end

  def test_enrichment_get_help
    stdout, _stderr, status = run_command("bundle exec exe/exa-ai enrichment-get --help")

    assert status.success?, "enrichment-get --help should succeed"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "webset_id"
    assert_includes stdout, "enrichment_id"
  end

  def test_enrichment_list_help
    stdout, _stderr, status = run_command("bundle exec exe/exa-ai enrichment-list --help")

    assert status.success?, "enrichment-list --help should succeed"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "webset_id"
  end

  def test_enrichment_update_help
    stdout, _stderr, status = run_command("bundle exec exe/exa-ai enrichment-update --help")

    assert status.success?, "enrichment-update --help should succeed"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "webset_id"
    assert_includes stdout, "enrichment_id"
    assert_includes stdout, "--description"
  end

  def test_enrichment_delete_help
    stdout, _stderr, status = run_command("bundle exec exe/exa-ai enrichment-delete --help")

    assert status.success?, "enrichment-delete --help should succeed"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "webset_id"
    assert_includes stdout, "enrichment_id"
    assert_includes stdout, "--force"
  end

  def test_enrichment_cancel_help
    stdout, _stderr, status = run_command("bundle exec exe/exa-ai enrichment-cancel --help")

    assert status.success?, "enrichment-cancel --help should succeed"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "webset_id"
    assert_includes stdout, "enrichment_id"
  end
end
