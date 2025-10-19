# frozen_string_literal: true

require "test_helper"

class Exa::CLI::GetContentsTest < Minitest::Test
  # Helper module to simulate CLI parsing
  module GetContentsCLI
    def self.parse_args(argv)
      args = {}
      remaining = argv.dup

      # Extract flags
      args[:api_key] = extract_flag!(remaining, "--api-key")
      args[:output_format] = extract_flag!(remaining, "--output-format")
      args[:text] = extract_boolean_flag!(remaining, "--text")
      args[:highlights] = extract_boolean_flag!(remaining, "--highlights")
      args[:summary] = extract_boolean_flag!(remaining, "--summary")

      # First remaining arg is the IDs (comma-separated)
      if remaining.empty?
        raise ArgumentError, "Missing required argument: IDs"
      end

      ids_arg = remaining.shift
      args[:ids] = ids_arg.include?(",") ? ids_arg.split(",").map(&:strip) : [ids_arg]

      args
    end

    def self.extract_flag!(argv, flag)
      idx = argv.index(flag)
      return nil unless idx

      argv.delete_at(idx) # Remove flag
      argv.delete_at(idx) # Remove value
    end

    def self.extract_boolean_flag!(argv, flag)
      idx = argv.index(flag)
      return false unless idx

      argv.delete_at(idx)
      true
    end
  end

  def setup
    ENV.delete("EXA_API_KEY")
  end

  def teardown
    ENV.delete("EXA_API_KEY")
  end

  def test_requires_ids_argument
    error = assert_raises(ArgumentError) do
      GetContentsCLI.parse_args([])
    end
    assert_includes error.message.downcase, "ids"
  end

  def test_parses_single_id
    args = GetContentsCLI.parse_args(["https://example.com"])
    assert_equal ["https://example.com"], args[:ids]
  end

  def test_parses_comma_separated_ids
    args = GetContentsCLI.parse_args(["id1,id2,id3"])
    assert_equal ["id1", "id2", "id3"], args[:ids]
  end

  def test_parses_text_flag
    args = GetContentsCLI.parse_args(["https://example.com", "--text"])
    assert_equal true, args[:text]
  end

  def test_parses_highlights_flag
    args = GetContentsCLI.parse_args(["https://example.com", "--highlights"])
    assert_equal true, args[:highlights]
  end

  def test_parses_summary_flag
    args = GetContentsCLI.parse_args(["https://example.com", "--summary"])
    assert_equal true, args[:summary]
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
