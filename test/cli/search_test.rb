# frozen_string_literal: true

require "test_helper"
require "exa/cli/search_parser"
require "tempfile"

class Exa::CLI::SearchTest < Minitest::Test
  def test_requires_query_argument
    # Test that command errors if no query provided
    error = assert_raises(ArgumentError) do
      parse_search_args([])
    end
    assert_includes error.message.downcase, "query"
  end

  def test_parses_query_from_argv
    args = parse_search_args(["ruby programming"])
    assert_equal "ruby programming", args[:query]
  end

  def test_parses_num_results_flag
    args = parse_search_args(["test query", "--num-results", "10"])
    assert_equal 10, args[:num_results]
  end

  def test_rejects_num_results_that_is_not_a_number
    _stdout, stderr = capture_io do
      error = assert_raises(SystemExit) do
        parse_search_args(["AI/ML infrastructure startups", "--num-results", "abc"])
      end
      assert_equal 1, error.status
    end

    assert_equal "Error: --num-results must be a number (got \"abc\")\n", stderr
  end

  def test_parses_type_flag
    %w[auto lite deep-lite neural fast deep deep-reasoning instant].each do |type|
      args = parse_search_args(["test query", "--type", type])
      assert_equal type, args[:type], "Failed to parse type: #{type}"
    end
  end

  def test_rejects_invalid_search_type
    %w[keyword invalid bogus].each do |type|
      error = assert_raises(ArgumentError) do
        parse_search_args(["test query", "--type", type])
      end
      assert_includes error.message.downcase, "search type"
    end
  end

  def test_parses_include_domains_flag
    args = parse_search_args(["test query", "--include-domains", "example.com,test.org"])
    assert_equal ["example.com", "test.org"], args[:include_domains]
  end

  def test_parses_exclude_domains_flag
    args = parse_search_args(["test query", "--exclude-domains", "spam.com,bad.org"])
    assert_equal ["spam.com", "bad.org"], args[:exclude_domains]
  end

  def test_outputs_json_by_default
    args = parse_search_args(["test query"])
    assert_equal "json", args[:output_format]
  end

  def test_outputs_pretty_format
    args = parse_search_args(["test query", "--output-format", "pretty"])
    assert_equal "pretty", args[:output_format]
  end

  def test_parses_category_people_flag
    args = parse_search_args(["John Smith software engineer", "--category", "people"])
    assert_equal "people", args[:category]
  end

  def test_parses_category_company_flag
    args = parse_search_args(["Anthropic AI safety", "--category", "company"])
    assert_equal "company", args[:category]
  end

  def test_parses_all_valid_categories
    valid_categories = ["company", "publication", "news", "personal site", "people", "financial report"]
    valid_categories.each do |category|
      args = parse_search_args(["test query", "--category", category])
      assert_equal category, args[:category], "Failed to parse category: #{category}"
    end
  end

  def test_rejects_invalid_category
    error = assert_raises(ArgumentError) do
      parse_search_args(["test query", "--category", "invalid"])
    end
    assert_includes error.message.downcase, "category"
  end

  def test_rejects_pdf_category
    error = assert_raises(ArgumentError) do
      parse_search_args(["test query", "--category", "pdf"])
    end
    assert_includes error.message.downcase, "category"
  end

  def test_rejects_obsolete_linkedin_profile_category
    error = assert_raises(ArgumentError) do
      parse_search_args(["test query", "--category", "linkedin profile"])
    end
    assert_includes error.message.downcase, "category"
  end

  # The search parser rejects --category github, which is not in the
  # spec's category list.
  def test_rejects_category_github
    error = assert_raises(ArgumentError) do
      parse_search_args(["Ruby HTTP client libraries", "--category", "github"])
    end
    assert_includes error.message.downcase, "category"
  end

  def test_parses_highlights_flag
    args = parse_search_args(["test query", "--highlights"])
    assert_equal true, args[:highlights]
  end

  def test_parses_highlights_options
    args = parse_search_args(["test query", "--highlights", "--highlights-max-characters", "500",
                              "--highlights-num-sentences", "3", "--highlights-per-url", "2",
                              "--highlights-query", "key points"])
    assert_equal true, args[:highlights]
    assert_equal 500, args[:highlights_max_characters]
    assert_equal 3, args[:highlights_num_sentences]
    assert_equal 2, args[:highlights_per_url]
    assert_equal "key points", args[:highlights_query]
  end

  def test_parses_livecrawl_flag
    args = parse_search_args(["test query", "--livecrawl"])
    assert_equal true, args[:livecrawl]
  end

  def test_parses_livecrawl_timeout_flag
    args = parse_search_args(["test query", "--livecrawl-timeout", "5000"])
    assert_equal 5000, args[:livecrawl_timeout]
  end

  def test_parses_max_age_hours_flag
    args = parse_search_args(["test query", "--max-age-hours", "24"])
    assert_equal 24, args[:max_age_hours]
  end

  def test_parses_additional_queries_repeatable
    args = parse_search_args(["test query", "--additional-queries", "Rails framework",
                              "--additional-queries", "Ruby gems"])
    assert_equal ["Rails framework", "Ruby gems"], args[:additional_queries]
  end

  def test_parses_output_schema_json_string
    args = parse_search_args(["test query", "--output-schema", '{"type":"object"}'])
    assert_equal({ "type" => "object" }, args[:output_schema])
  end

  def test_parses_user_location_flag
    args = parse_search_args(["test query", "--user-location", "US"])
    assert_equal "US", args[:user_location]
  end

  def test_parses_system_prompt_flag
    args = parse_search_args(["test query", "--system-prompt", "You are a helpful assistant"])
    assert_equal "You are a helpful assistant", args[:system_prompt]
  end

  def test_parses_moderation_flag
    args = parse_search_args(["test query", "--moderation"])
    assert_equal true, args[:moderation]
  end

  def test_parses_text_verbosity_flag
    args = parse_search_args(["test query", "--text-verbosity", "compact"])
    assert_equal "compact", args[:text_verbosity]
  end

  def test_rejects_invalid_text_verbosity
    error = assert_raises(ArgumentError) do
      parse_search_args(["test query", "--text-verbosity", "verbose"])
    end
    assert_includes error.message.downcase, "verbosity"
  end

  def test_handles_api_error_gracefully
    stub_request(:post, "https://api.exa.ai/search")
      .to_return(status: 500, body: { error: "Internal Server Error" }.to_json)

    # This test will be implemented when we have the actual command
    # For now, just verify WebMock is set up
    assert true
  end

  def test_parses_objective_flag
    args = parse_search_args(["climate startups", "--objective", "Find primary sources"])
    assert_equal "Find primary sources", args[:objective]
  end

  def test_parses_user_identifier_flag
    args = parse_search_args(["climate startups", "--user-identifier", "user_42"])
    assert_equal "user_42", args[:user_identifier]
  end

  def test_parses_compliance_flag
    args = parse_search_args(["climate startups", "--compliance", "hipaa"])
    assert_equal "hipaa", args[:compliance]
  end

  def test_rejects_unknown_compliance_value
    error = assert_raises(ArgumentError) do
      parse_search_args(["climate startups", "--compliance", "gdpr"])
    end
    assert_includes error.message.downcase, "compliance"
  end

  def test_parses_snapshot_as_of_flag
    args = parse_search_args(["climate startups", "--snapshot-as-of", "2026-01-01T00:00:00Z"])
    assert_equal "2026-01-01T00:00:00Z", args[:snapshot_as_of]
  end

  def test_parses_user_location_json_object
    args = parse_search_args(["coffee near me", "--user-location", '{"country":"US","latitude":37.77,"longitude":-122.42}'])
    assert_equal({ "country" => "US", "latitude" => 37.77, "longitude" => -122.42 }, args[:user_location])
  end

  def test_parses_user_location_from_file
    Tempfile.create(["location", ".json"]) do |file|
      file.write('{"country":"GB"}')
      file.flush
      args = parse_search_args(["coffee near me", "--user-location", "@#{file.path}"])
      assert_equal({ "country" => "GB" }, args[:user_location])
    end
  end

  def test_exe_rejects_invalid_user_location_json_with_one_line
    stub_request(:post, "https://api.exa.ai/search")

    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-search", "AI infrastructure startups", "--user-location", "{bad", "--api-key", "test_key"
    )

    assert_equal 1, exit_status
    assert_equal 1, stderr.lines.count
    assert_match(/\AError: --user-location is not valid JSON/, stderr)
    assert_not_requested :post, "https://api.exa.ai/search"
  end

  def test_help_lists_new_flags
    output = `bundle exec exe/exa-ai-search --help`

    %w[--objective --user-identifier --compliance --snapshot-as-of].each do |flag|
      assert_includes output, flag
    end
  end

  def test_exe_sends_new_flags_in_request_body
    posted_body = nil
    stub_request(:post, "https://api.exa.ai/search")
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    run_exe_in_process(
      "exa-ai-search", "coffee near me", "--api-key", "test_key",
      "--objective", "Find primary sources", "--user-identifier", "user_42",
      "--compliance", "hipaa", "--snapshot-as-of", "2026-01-01T00:00:00Z",
      "--user-location", '{"country":"US"}'
    )

    assert_equal "Find primary sources", posted_body["objective"]
    assert_equal "user_42", posted_body["userIdentifier"]
    assert_equal "hipaa", posted_body["compliance"]
    assert_equal "2026-01-01T00:00:00Z", posted_body.dig("contents", "snapshotAsOf")
    assert_equal({ "country" => "US" }, posted_body["userLocation"])
  end

  def test_exe_prints_warnings_to_stderr
    warnings = [{ "code" => "PARAM_IGNORED", "path" => "contents.livecrawl", "message" => "livecrawl is ignored for lite search" }]
    stub_request(:post, "https://api.exa.ai/search")
      .to_return(status: 200, body: { results: [], warnings: warnings }.to_json, headers: { "Content-Type" => "application/json" })

    stdout, stderr = run_exe_in_process("exa-ai-search", "coffee near me", "--api-key", "test_key", "--output-format", "json")

    assert_includes stderr, "Warning: livecrawl is ignored for lite search (contents.livecrawl)"
    refute_includes stdout, "Warning:"
  end

  def test_print_request_writes_the_sent_body_to_stderr
    sent_body = nil
    stub_request(:post, "https://api.exa.ai/search")
      .with { |request| sent_body = request.body }
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-search", "venture-backed SaaS companies", "--num-results", "2", "--text",
      "--text-max-characters", "500", "--print-request", "--api-key", "test_key"
    )

    assert_nil exit_status
    assert_equal 1, stderr.lines.count
    assert_equal sent_body, stderr.chomp
    assert_equal({ "maxCharacters" => 500 }, JSON.parse(stderr).dig("contents", "text"))
    assert_equal [], JSON.parse(stdout)["results"]
    refute_includes stderr, "test_key"
    refute_includes stderr, "x-api-key"
    refute_includes sent_body, "print"
  end

  def test_without_print_request_stderr_is_empty
    stub_request(:post, "https://api.exa.ai/search")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    _stdout, stderr = run_exe_in_process("exa-ai-search", "venture-backed SaaS companies", "--api-key", "test_key")

    assert_empty stderr
  end

  def test_print_request_with_help_prints_only_help
    stub_request(:post, "https://api.exa.ai/search")

    stdout, stderr, exit_status = run_exe_in_process("exa-ai-search", "--print-request", "--help")

    assert_equal 0, exit_status
    assert_includes stdout, "Usage: exa-ai search"
    assert_empty stderr
    assert_not_requested :post, "https://api.exa.ai/search"
  end

  def test_print_request_with_unknown_flag_prints_only_the_error
    stub_request(:post, "https://api.exa.ai/search")

    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-search", "venture-backed SaaS companies", "--print-request", "--bogus", "--api-key", "test_key"
    )

    refute_equal 0, exit_status
    assert_equal "Error: unknown option --bogus\n", stderr
    assert_not_requested :post, "https://api.exa.ai/search"
  end

  def test_help_mentions_print_request
    stdout, = run_exe_in_process("exa-ai-search", "--help")

    assert_includes stdout, "--print-request"
  end

  def test_user_location_without_value_is_skipped
    args = parse_search_args(["coffee near me", "--user-location"])
    assert_nil args[:user_location]
  end

  private

  # Helper method to parse command-line arguments
  # Uses the real SearchParser implementation to avoid code duplication
  def parse_search_args(argv)
    Exa::CLI::SearchParser.parse(argv)
  end
end
