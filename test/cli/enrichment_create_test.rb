# frozen_string_literal: true

require "test_helper"

class Exa::CLI::EnrichmentCreateTest < Minitest::Test
  WEBSET_ID = "ws_climate_tech"
  ENRICHMENTS_URL = "https://api.exa.ai/websets/v0/websets/#{WEBSET_ID}/enrichments"

  # Test that CLI uses the correct format constant
  def test_cli_script_uses_correct_format_constant
    cli_content = File.read(File.expand_path("../../exe/exa-ai-enrichment-create", __dir__))

    # The CLI should use the constant from Exa::Constants::Websets
    assert_includes cli_content, "Exa::Constants::Websets::ENRICHMENT_FORMATS",
      "CLI should use Exa::Constants::Websets::ENRICHMENT_FORMATS instead of hardcoded list"
  end

  def test_format_constant_includes_all_valid_formats
    # Verify the constant has all 7 valid formats per API spec
    expected_formats = %w[text date number options email phone url]
    assert_equal expected_formats.sort, Exa::Constants::Websets::ENRICHMENT_FORMATS.sort
  end

  def test_sends_each_valid_format_in_request_body
    Exa::Constants::Websets::ENRICHMENT_FORMATS.each do |format|
      flags = ["--description", "Number of full-time employees", "--format", format]
      flags += ["--options", '[{"label":"Hardware"},{"label":"Software"}]'] if format == "options"

      body = post_enrichment(*flags)

      assert_equal format, body["format"], "format #{format} should reach the request body"
      assert_equal "Number of full-time employees", body["description"]
    end
  end

  def test_sends_options_and_metadata_parsed_from_json
    body = post_enrichment(
      "--description", "Primary industry", "--format", "options",
      "--options", '[{"label":"Solar"},{"label":"Battery storage"}]',
      "--metadata", '{"owner":"research-team"}'
    )

    assert_equal [{ "label" => "Solar" }, { "label" => "Battery storage" }], body["options"]
    assert_equal({ "owner" => "research-team" }, body["metadata"])
  end

  def test_rejects_invalid_format_before_any_request
    stub_request(:post, ENRICHMENTS_URL)

    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-enrichment-create", WEBSET_ID,
      "--description", "Annual report", "--format", "pdf", "--api-key", "test_key"
    )

    assert_equal 1, exit_status
    assert_includes stderr, "format must be one of"
    assert_not_requested :post, ENRICHMENTS_URL
  end

  private

  # Runs exa-ai-enrichment-create in-process with the given flags and
  # returns the parsed body of the request it sends.
  def post_enrichment(*flags)
    posted_body = nil
    stub_request(:post, ENRICHMENTS_URL)
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(
        status: 200,
        body: { id: "enr_employee_count", object: "webset_enrichment", status: "pending", websetId: WEBSET_ID }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-enrichment-create", WEBSET_ID, *flags, "--api-key", "test_key"
    )

    assert_nil exit_status, "command failed: #{stderr}"
    posted_body
  end
end
