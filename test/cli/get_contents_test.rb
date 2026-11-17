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
    posted_body = nil
    stub_request(:post, "https://api.exa.ai/contents")
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    run_exe_in_process(
      "exa-ai-get-contents", "--api-key", "test_key", "--text", "--text-max-characters", "3000",
      "https://www.anthropic.com/research"
    )

    assert_equal ["https://www.anthropic.com/research"], posted_body["urls"]
    assert_equal({ "maxCharacters" => 3000 }, posted_body["text"])
  end

  def test_cli_help_lists_spec_catch_up_flags
    output = `bundle exec exe/exa-ai-get-contents --help`

    %w[--max-age-hours --snapshot-as-of --ids --user-identifier --compliance --highlights
       --highlights-query --highlights-max-characters --highlights-verbosity --text-verbosity].each do |flag|
      assert_includes output, flag
    end
  end

  def test_client_get_contents_with_only_ids_sends_no_urls
    posted_body = nil
    stub_request(:post, "https://api.exa.ai/contents")
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    Exa::Client.new(api_key: "test_key").get_contents(ids: ["doc_1"])

    assert_equal ["doc_1"], posted_body["ids"]
    refute posted_body.key?("urls")
  end

  def test_exe_sends_new_flags_in_request_body
    posted_body = nil
    stub_request(:post, "https://api.exa.ai/contents")
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    run_exe_in_process(
      "exa-ai-get-contents", "https://www.anthropic.com/research", "--api-key", "test_key",
      "--max-age-hours", "24", "--snapshot-as-of", "2026-01-01T00:00:00Z",
      "--user-identifier", "user_42", "--compliance", "hipaa",
      "--text", "--text-verbosity", "compact",
      "--highlights", "--highlights-query", "funding", "--highlights-max-characters", "300",
      "--highlights-verbosity", "low"
    )

    assert_equal ["https://www.anthropic.com/research"], posted_body["urls"]
    assert_equal 24, posted_body["maxAgeHours"]
    assert_equal "2026-01-01T00:00:00Z", posted_body["snapshotAsOf"]
    assert_equal "user_42", posted_body["userIdentifier"]
    assert_equal "hipaa", posted_body["compliance"]
    assert_equal({ "verbosity" => "compact" }, posted_body["text"])
    assert_equal({ "query" => "funding", "maxCharacters" => 300, "verbosity" => "low" }, posted_body["highlights"])
    assert_requested :post, "https://api.exa.ai/contents", headers: { "Exa-Beta" => "dynamic-highlights-2026-08-28" }
  end

  def test_exe_sends_plain_highlights_as_true
    posted_body = nil
    stub_request(:post, "https://api.exa.ai/contents")
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    run_exe_in_process("exa-ai-get-contents", "https://www.anthropic.com/research", "--api-key", "test_key", "--highlights")

    assert_equal true, posted_body["highlights"]
  end

  def test_exe_sends_ids_without_urls
    posted_body = nil
    stub_request(:post, "https://api.exa.ai/contents")
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    run_exe_in_process("exa-ai-get-contents", "--ids", "doc_1,doc_2", "--api-key", "test_key")

    assert_equal %w[doc_1 doc_2], posted_body["ids"]
    refute posted_body.key?("urls")
  end

  def test_exe_errors_when_neither_urls_nor_ids_given
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    _stdout, stderr, exit_status = run_exe_in_process("exa-ai-get-contents", "--api-key", "test_key")

    assert_equal 1, exit_status
    assert_includes stderr, "--ids"
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
end
