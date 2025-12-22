# frozen_string_literal: true

require "test_helper"
require "exa/cli/search_parser"

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

  def test_parses_type_flag
    args = parse_search_args(["test query", "--type", "fast"])
    assert_equal "fast", args[:type]

    args = parse_search_args(["test query", "--type", "deep"])
    assert_equal "deep", args[:type]

    args = parse_search_args(["test query", "--type", "keyword"])
    assert_equal "keyword", args[:type]

    args = parse_search_args(["test query", "--type", "auto"])
    assert_equal "auto", args[:type]
  end

  def test_rejects_invalid_search_type
    error = assert_raises(ArgumentError) do
      parse_search_args(["test query", "--type", "neural"])
    end
    assert_includes error.message.downcase, "search type"

    error = assert_raises(ArgumentError) do
      parse_search_args(["test query", "--type", "invalid"])
    end
    assert_includes error.message.downcase, "search type"
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
    valid_categories = ["company", "research paper", "news", "pdf", "github", "tweet", "personal site", "financial report", "people"]
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

  def test_rejects_obsolete_linkedin_profile_category
    error = assert_raises(ArgumentError) do
      parse_search_args(["test query", "--category", "linkedin profile"])
    end
    assert_includes error.message.downcase, "category"
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
  # Uses the real SearchParser implementation to avoid code duplication
  def parse_search_args(argv)
    Exa::CLI::SearchParser.parse(argv)
  end
end
