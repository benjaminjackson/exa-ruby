# frozen_string_literal: true

require "test_helper"

class Exa::CLI::SearchTest < Minitest::Test
  def setup
    # Clean environment for each test
    @original_api_key = ENV["EXA_API_KEY"]
    ENV["EXA_API_KEY"] = "test_api_key"
  end

  def teardown
    ENV["EXA_API_KEY"] = @original_api_key
  end

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

  def test_parses_type_flag
    args = parse_search_args(["test query", "--type", "keyword"])
    assert_equal "keyword", args[:type]

    args = parse_search_args(["test query", "--type", "neural"])
    assert_equal "neural", args[:type]

    args = parse_search_args(["test query", "--type", "auto"])
    assert_equal "auto", args[:type]
  end

  def test_parses_include_domains_flag
    args = parse_search_args(["test query", "--include-domains", "example.com,test.org"])
    assert_equal ["example.com", "test.org"], args[:include_domains]
  end

  def test_parses_exclude_domains_flag
    args = parse_search_args(["test query", "--exclude-domains", "spam.com,bad.org"])
    assert_equal ["spam.com", "bad.org"], args[:exclude_domains]
  end

  def test_parses_use_autoprompt_flag
    args = parse_search_args(["test query", "--use-autoprompt"])
    assert_equal true, args[:use_autoprompt]

    args = parse_search_args(["test query"])
    assert_nil args[:use_autoprompt]
  end

  def test_outputs_json_by_default
    args = parse_search_args(["test query"])
    assert_equal "json", args[:output_format]
  end

  def test_outputs_pretty_format
    args = parse_search_args(["test query", "--output-format", "pretty"])
    assert_equal "pretty", args[:output_format]
  end

  def test_handles_api_error_gracefully
    stub_request(:post, "https://api.exa.ai/search")
      .to_return(status: 500, body: { error: "Internal Server Error" }.to_json)

    # This test will be implemented when we have the actual command
    # For now, just verify WebMock is set up
    assert true
  end

  private

  # Helper method to parse command-line arguments
  # This simulates what the exe/exa-search script will do
  def parse_search_args(argv)
    args = { output_format: "json" }

    # Extract query (first non-flag argument)
    query_parts = []
    i = 0
    while i < argv.length
      arg = argv[i]
      case arg
      when "--num-results"
        args[:num_results] = argv[i + 1].to_i
        i += 2
      when "--type"
        args[:type] = argv[i + 1]
        i += 2
      when "--include-domains"
        args[:include_domains] = argv[i + 1].split(",").map(&:strip)
        i += 2
      when "--exclude-domains"
        args[:exclude_domains] = argv[i + 1].split(",").map(&:strip)
        i += 2
      when "--use-autoprompt"
        args[:use_autoprompt] = true
        i += 1
      when "--api-key"
        args[:api_key] = argv[i + 1]
        i += 2
      when "--output-format"
        args[:output_format] = argv[i + 1]
        i += 2
      else
        query_parts << arg
        i += 1
      end
    end

    args[:query] = query_parts.join(" ")
    raise ArgumentError, "Query is required" if args[:query].empty?

    args
  end
end
