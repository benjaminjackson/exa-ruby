# frozen_string_literal: true

require "test_helper"
require "tempfile"

class Exa::CLI::ImportCreateTest < Minitest::Test
  IMPORTS_URL = "https://api.exa.ai/websets/v0/imports"
  UPLOAD_URL = "https://uploads.exa.ai/imports/imp_series_a_startups"
  CSV_CONTENT = "name,website\nAnthropic,anthropic.com\nMistral AI,mistral.ai\n"

  def setup
    super
    @csv_file = Tempfile.new(["series_a_startups", ".csv"])
    @csv_file.write(CSV_CONTENT)
    @csv_file.flush
  end

  def teardown
    @csv_file.close
    @csv_file.unlink
    super
  end

  def test_sends_count_title_format_and_entity_type_in_request_body
    body, = post_import("--count", "50", "--title", "Series A AI startups", "--entity-type", "company")

    assert_equal 50, body["count"]
    assert_equal "Series A AI startups", body["title"]
    assert_equal "csv", body["format"]
    assert_equal({ "type" => "company" }, body["entity"])
  end

  def test_uploads_contents_of_file_given_as_first_argument
    post_import("--count", "2", "--title", "Series A AI startups", "--entity-type", "company")

    assert_requested(:put, UPLOAD_URL, body: CSV_CONTENT)
  end

  def test_sends_custom_entity_with_description
    body, = post_import(
      "--count", "2", "--title", "Climate nonprofits",
      "--entity-type", "custom", "--entity-description", "nonprofit climate advocacy organizations"
    )

    assert_equal({ "type" => "custom", "description" => "nonprofit climate advocacy organizations" }, body["entity"])
  end

  def test_custom_entity_without_description_exits_before_any_request
    stub_request(:post, IMPORTS_URL)

    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-import-create", @csv_file.path,
      "--count", "2", "--title", "Climate nonprofits", "--entity-type", "custom", "--api-key", "test_key"
    )

    assert_equal 1, exit_status
    assert_includes stderr, "--entity-description is required"
    assert_not_requested :post, IMPORTS_URL
  end

  # The command warns that it ignores --entity-description for a type
  # other than custom, but it still sends the description to the API.
  def test_warns_but_still_sends_entity_description_for_non_custom_type
    body, stderr = post_import(
      "--count", "2", "--title", "AI researchers",
      "--entity-type", "person", "--entity-description", "machine learning researchers"
    )

    assert_includes stderr, "Warning: --entity-description is only used with --entity-type custom"
    assert_equal({ "type" => "person", "description" => "machine learning researchers" }, body["entity"])
  end

  def test_sends_csv_identifier_in_request_body
    body, = post_import(
      "--count", "2", "--title", "Series A AI startups", "--entity-type", "company", "--csv-identifier", "1"
    )

    assert_equal({ "identifier" => 1 }, body["csv"])
  end

  def test_sends_metadata_parsed_from_json
    body, = post_import(
      "--count", "2", "--title", "Series A AI startups", "--entity-type", "company",
      "--metadata", '{"source":"crm"}'
    )

    assert_equal({ "source" => "crm" }, body["metadata"])
  end

  def test_quiet_flag_suppresses_output
    _body, stderr, stdout = post_import(
      "--count", "2", "--title", "Series A AI startups", "--entity-type", "company", "--quiet"
    )

    assert_empty stdout
    assert_empty stderr
  end

  def test_prints_json_by_default
    _body, _stderr, stdout = post_import("--count", "2", "--title", "Series A AI startups", "--entity-type", "company")

    assert_equal "imp_series_a_startups", JSON.parse(stdout)["id"]
  end

  def test_prints_pretty_output_when_asked
    _body, _stderr, stdout = post_import(
      "--count", "2", "--title", "Series A AI startups", "--entity-type", "company", "--output-format", "pretty"
    )

    assert_includes stdout, "Import ID:     imp_series_a_startups"
  end

  private

  # Runs exa-ai-import-create in-process on the temporary CSV file with the
  # given flags. Returns the parsed body of the create request, stderr and
  # stdout. The upload of the file to its upload URL is stubbed too.
  def post_import(*flags)
    posted_body = nil
    stub_request(:post, IMPORTS_URL)
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(
        status: 200,
        body: {
          id: "imp_series_a_startups", object: "import", status: "pending",
          title: "Series A AI startups", uploadUrl: UPLOAD_URL
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    stub_request(:put, UPLOAD_URL).to_return(status: 200)

    stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-import-create", @csv_file.path, *flags, "--api-key", "test_key"
    )

    assert_nil exit_status, "command failed: #{stderr}"
    [posted_body, stderr, stdout]
  end
end
