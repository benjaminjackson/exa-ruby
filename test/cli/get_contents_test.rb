# frozen_string_literal: true

require "test_helper"

class Exa::CLI::GetContentsTest < Minitest::Test
  def test_cli_help_shows_new_options
    # Test that the CLI help includes all new flags
    command = "bundle exec exe/exa-ai-get-contents --help"
    output = `#{command}`

    assert_includes output, "Retrieve full page contents from URLs"
    assert_includes output, "--text-max-characters"
    assert_includes output, "--include-html-tags"
    assert_includes output, "--summary-query"
    assert_includes output, "--summary-schema"
    assert_includes output, "--subpages"
    assert_includes output, "--subpage-target"
    assert_includes output, "--links"
    assert_includes output, "--image-links"
    assert_includes output, "--context"
    assert_includes output, "--context-max-characters"
    assert_includes output, "--livecrawl-timeout"
  end

  def test_client_accepts_text_object_params
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.get_contents(
      ["https://example.com"],
      text: { max_characters: 3000, include_html_tags: true }
    )
    assert result
  end

  def test_client_accepts_summary_object_params
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    schema = {
      "type" => "object",
      "properties" => { "answer" => { "type" => "string" } }
    }
    result = client.get_contents(
      ["https://example.com"],
      summary: { query: "Be terse", schema: schema }
    )
    assert result
  end

  def test_client_accepts_extras_params
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.get_contents(
      ["https://example.com"],
      extras: { links: 5, image_links: 10 }
    )
    assert result
  end

  def test_client_accepts_subpage_params
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.get_contents(
      ["https://example.com"],
      subpages: 1,
      subpage_target: ["about"]
    )
    assert result
  end

  def test_client_accepts_context_params
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123", context: "Test context" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.get_contents(
      ["https://example.com"],
      context: { max_characters: 5000 }
    )
    assert result
  end

  def test_client_accepts_livecrawl_timeout
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.get_contents(
      ["https://example.com"],
      livecrawl_timeout: 1000
    )
    assert result
  end

  def test_outputs_json_by_default
    # Stub the API call
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(
        status: 200,
        body: {
          results: [{ url: "https://example.com", title: "Test", text: "Content" }],
          requestId: "test123"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.get_contents(["https://example.com"])

    # Default format should be JSON
    output = Exa::CLI::Base.format_output(result.to_h, "json")
    parsed = JSON.parse(output)
    assert_equal "test123", parsed["request_id"]
  end

  def test_outputs_pretty_format
    # Stub the API call
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(
        status: 200,
        body: {
          results: [{ url: "https://example.com", title: "Test", text: "Content" }],
          requestId: "test123"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.get_contents(["https://example.com"])

    # Pretty format uses inspect
    output = Exa::CLI::Base.format_output(result, "pretty")
    assert_instance_of String, output
    refute_empty output
  end

  def test_handles_api_error_gracefully
    # Stub a 401 error
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(
        status: 401,
        body: { error: "Unauthorized" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")

    error = assert_raises(Exa::Unauthorized) do
      client.get_contents(["https://example.com"])
    end

    assert_instance_of Exa::Unauthorized, error
  end

  def test_exe_reads_url_after_options_that_take_values
    posted = stub_contents_and_capture_body

    run_exe_in_process(
      "exa-ai-get-contents", "--api-key", "test_key", "--text", "--text-max-characters", "3000",
      "https://www.anthropic.com/research"
    )

    assert_equal ["https://www.anthropic.com/research"], posted[:body]["urls"]
    assert_equal({ "maxCharacters" => 3000 }, posted[:body]["text"])
  end

  def test_cli_help_lists_spec_catch_up_flags
    output = `bundle exec exe/exa-ai-get-contents --help`

    %w[--max-age-hours --snapshot-as-of --ids --user-identifier --compliance --highlights
       --highlights-query --highlights-max-characters --highlights-verbosity --text-verbosity].each do |flag|
      assert_includes output, flag
    end
  end

  def test_client_get_contents_with_only_ids_sends_no_urls
    posted = stub_contents_and_capture_body

    Exa::Client.new(api_key: "test_key").get_contents(ids: ["doc_1"])

    assert_equal ["doc_1"], posted[:body]["ids"]
    refute posted[:body].key?("urls")
  end

  def test_exe_sends_new_flags_in_request_body
    posted = stub_contents_and_capture_body

    run_exe_in_process(
      "exa-ai-get-contents", "https://www.anthropic.com/research", "--api-key", "test_key",
      "--max-age-hours", "24", "--snapshot-as-of", "2026-01-01T00:00:00Z",
      "--user-identifier", "user_42", "--compliance", "hipaa",
      "--text", "--text-verbosity", "compact",
      "--highlights", "--highlights-query", "funding", "--highlights-max-characters", "300",
      "--highlights-verbosity", "low"
    )

    assert_equal ["https://www.anthropic.com/research"], posted[:body]["urls"]
    assert_equal 24, posted[:body]["maxAgeHours"]
    assert_equal "2026-01-01T00:00:00Z", posted[:body]["snapshotAsOf"]
    assert_equal "user_42", posted[:body]["userIdentifier"]
    assert_equal "hipaa", posted[:body]["compliance"]
    assert_equal({ "verbosity" => "compact" }, posted[:body]["text"])
    assert_equal({ "query" => "funding", "maxCharacters" => 300, "verbosity" => "low" }, posted[:body]["highlights"])
    assert_requested :post, "https://api.exa.ai/contents", headers: { "Exa-Beta" => "dynamic-highlights-2026-08-28" }
  end

  def test_exe_sends_plain_highlights_as_true
    posted = stub_contents_and_capture_body

    run_exe_in_process("exa-ai-get-contents", "https://www.anthropic.com/research", "--api-key", "test_key", "--highlights")

    assert_equal true, posted[:body]["highlights"]
  end

  def test_exe_sends_ids_without_urls
    posted = stub_contents_and_capture_body

    run_exe_in_process("exa-ai-get-contents", "--ids", "doc_1,doc_2", "--api-key", "test_key")

    assert_equal %w[doc_1 doc_2], posted[:body]["ids"]
    refute posted[:body].key?("urls")
  end

  def test_exe_errors_when_neither_urls_nor_ids_given
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    _stdout, stderr, exit_status = run_exe_in_process("exa-ai-get-contents", "--api-key", "test_key")

    assert_equal 1, exit_status
    assert_includes stderr, "--ids"
    assert_not_requested :post, "https://api.exa.ai/contents"
  end

  def test_print_request_writes_the_sent_body_to_stderr
    sent_body = nil
    stub_request(:post, "https://api.exa.ai/contents")
      .with { |request| sent_body = request.body }
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-get-contents", "https://exa.ai", "--max-age-hours", "0", "--print-request", "--api-key", "test_key"
    )

    assert_nil exit_status
    assert_equal 1, stderr.lines.count
    assert_equal sent_body, stderr.chomp
    assert_includes stderr, '"maxAgeHours":0'
    assert_equal [], JSON.parse(stdout)["results"]
    refute_includes stderr, "test_key"
    refute_includes stderr, "x-api-key"
    refute_includes sent_body, "print"
  end

  def test_without_print_request_stderr_is_empty
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    _stdout, stderr = run_exe_in_process("exa-ai-get-contents", "https://exa.ai", "--api-key", "test_key")

    assert_empty stderr
  end

  def test_print_request_with_help_prints_only_help
    stub_request(:post, "https://api.exa.ai/contents")

    stdout, stderr, exit_status = run_exe_in_process("exa-ai-get-contents", "--print-request", "--help")

    assert_equal 0, exit_status
    assert_includes stdout, "Usage: exa-ai get-contents"
    assert_includes stdout, "--print-request"
    assert_empty stderr
    assert_not_requested :post, "https://api.exa.ai/contents"
  end

  def test_client_get_contents_posts_urls_as_first_body_key
    raw_body = nil
    stub_request(:post, "https://api.exa.ai/contents")
      .with { |request| raw_body = request.body }
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    Exa::Client.new(api_key: "test_key").get_contents(["https://www.anthropic.com/research"], text: true)

    assert_equal "urls", JSON.parse(raw_body).keys.first
  end

  def test_client_get_contents_without_urls_or_ids_raises_argument_error
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    assert_raises(ArgumentError) { Exa::Client.new(api_key: "test_key").get_contents(text: true) }
    assert_not_requested :post, "https://api.exa.ai/contents"
  end

  def test_client_get_contents_with_empty_urls_or_ids_raises_argument_error
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })
    client = Exa::Client.new(api_key: "test_key")

    assert_raises(ArgumentError) { client.get_contents([]) }
    assert_raises(ArgumentError) { client.get_contents(ids: []) }
    assert_not_requested :post, "https://api.exa.ai/contents"
  end

  def test_client_get_contents_accepts_urls_keyword
    posted = stub_contents_and_capture_body

    Exa::Client.new(api_key: "test_key").get_contents(urls: ["https://www.anthropic.com/research"])

    assert_equal ["https://www.anthropic.com/research"], posted[:body]["urls"]
  end

  def test_exe_sends_the_same_body_for_every_shared_contents_flag
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    _stdout, stderr, _exit_status = run_exe_in_process(
      "exa-ai-get-contents", "https://exa.ai", "--api-key", "test_key", "--print-request",
      "--text", "--text-max-characters", "100", "--include-html-tags", "--text-verbosity", "compact",
      "--summary", "--summary-query", "Name the founders", "--summary-schema", '{"type":"object"}',
      "--context", "--context-max-characters", "50",
      "--subpages", "1", "--subpage-target", "about", "--subpage-target", "careers",
      "--links", "2", "--image-links", "3",
      "--highlights", "--highlights-query", "funding rounds", "--highlights-max-characters", "10",
      "--highlights-verbosity", "low",
      "--livecrawl-timeout", "1000", "--max-age-hours", "0", "--snapshot-as-of", "2024-01-01"
    )

    expected_body = '{"urls":["https://exa.ai"],' \
                    '"text":{"maxCharacters":100,"includeHtmlTags":true,"verbosity":"compact"},' \
                    '"summary":{"query":"Name the founders","schema":{"type":"object"}},' \
                    '"context":{"maxCharacters":50},"subpages":1,"subpageTarget":["about","careers"],' \
                    '"extras":{"links":2,"imageLinks":3},' \
                    '"highlights":{"query":"funding rounds","maxCharacters":10,"verbosity":"low"},' \
                    '"livecrawlTimeout":1000,"maxAgeHours":0,"snapshotAsOf":"2024-01-01"}'
    assert_equal expected_body, stderr.lines.first.chomp
  end

  %w[--snapshot-as-of --summary-query --highlights-query --subpage-target].each do |flag|
    flag_name = flag.delete_prefix("--").tr("-", "_")

    define_method("test_exe_stops_when_#{flag_name}_comes_last_with_no_value") do
      stub_request(:post, "https://api.exa.ai/contents")

      _stdout, stderr, exit_status = run_exe_in_process(
        "exa-ai-get-contents", "https://exa.ai", "--api-key", "test_key", flag
      )

      assert_equal "Error: #{flag} needs a value\n", stderr
      refute_equal 0, exit_status
      assert_not_requested :post, "https://api.exa.ai/contents"
    end

    define_method("test_exe_stops_when_#{flag_name}_is_followed_by_another_flag") do
      stub_request(:post, "https://api.exa.ai/contents")

      _stdout, stderr, exit_status = run_exe_in_process(
        "exa-ai-get-contents", "https://exa.ai", "--api-key", "test_key", flag, "--text"
      )

      assert_equal "Error: #{flag} needs a value (got the flag --text)\n", stderr
      refute_equal 0, exit_status
      assert_not_requested :post, "https://api.exa.ai/contents"
    end
  end

  %w[--bogus --livecrawl --highlights-num-sentences --highlights-per-url].each do |flag|
    flag_name = flag.delete_prefix("--").tr("-", "_")

    define_method("test_exe_rejects_unknown_option_#{flag_name}_after_the_url") do
      stub_request(:post, "https://api.exa.ai/contents")

      _stdout, stderr, exit_status = run_exe_in_process(
        "exa-ai-get-contents", "https://exa.ai", flag, "--api-key", "test_key"
      )

      assert_equal "Error: unknown option #{flag}\n", stderr
      refute_equal 0, exit_status
      assert_not_requested :post, "https://api.exa.ai/contents"
    end
  end

  def test_exe_rejects_unknown_option_before_the_url
    stub_request(:post, "https://api.exa.ai/contents")

    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-get-contents", "--bogus", "https://exa.ai", "--api-key", "test_key"
    )

    assert_equal "Error: unknown option --bogus\n", stderr
    refute_equal 0, exit_status
    assert_not_requested :post, "https://api.exa.ai/contents"
  end

  def test_exe_accepts_every_flag_in_the_help_text
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })
    help_text, = run_exe_in_process("exa-ai-get-contents", "--help")
    values_by_flag = {
      "--text" => nil, "--text-max-characters" => "3000", "--include-html-tags" => nil,
      "--text-verbosity" => "compact", "--summary" => nil, "--summary-query" => "Name the founders",
      "--summary-schema" => '{"type":"object"}', "--context" => nil, "--context-max-characters" => "500",
      "--subpages" => "1", "--subpage-target" => "careers", "--links" => "5", "--image-links" => "10",
      "--highlights" => nil, "--highlights-query" => "funding rounds", "--highlights-max-characters" => "300",
      "--highlights-verbosity" => "low", "--livecrawl-timeout" => "5000", "--max-age-hours" => "24",
      "--snapshot-as-of" => "2026-01-01T00:00:00Z", "--ids" => "doc_1", "--user-identifier" => "user_42",
      "--compliance" => "hipaa", "--api-key" => "test_key", "--output-format" => "json",
      "--print-request" => nil
    }
    assert_equal help_text.scan(/--[a-z][a-z-]*/).uniq.sort - ["--help", "--flags-json"], values_by_flag.keys.sort

    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-get-contents", "https://exa.ai", *values_by_flag.flat_map { |flag, value| [flag, value].compact }
    )

    assert_nil exit_status
    assert_equal 1, stderr.lines.count
    assert_requested :post, "https://api.exa.ai/contents"
  end

  def test_contents_flags_parse_reads_a_contents_flag
    parsed = {}

    next_index = Exa::CLI::ContentsFlags.parse(["--livecrawl"], 0, parsed)

    assert_equal 1, next_index
    assert_equal({ livecrawl: true }, parsed)
  end

  private

  # Stubs /contents and returns a Hash whose :body is set to the parsed
  # JSON request body once a request is made.
  def stub_contents_and_capture_body
    posted = {}
    stub_request(:post, "https://api.exa.ai/contents")
      .with { |request| posted[:body] = JSON.parse(request.body) }
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })
    posted
  end
end
