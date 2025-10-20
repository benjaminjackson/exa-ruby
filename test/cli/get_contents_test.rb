# frozen_string_literal: true

require "test_helper"

class Exa::CLI::GetContentsTest < Minitest::Test
  def setup
    ENV.delete("EXA_API_KEY")
  end

  def teardown
    ENV.delete("EXA_API_KEY")
  end

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
end
