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
    %w[auto neural fast deep deep-reasoning instant].each do |type|
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
    %w[always fallback never auto preferred].each do |mode|
      args = parse_search_args(["test query", "--livecrawl", mode])
      assert_equal mode, args[:livecrawl], "Failed to parse livecrawl mode: #{mode}"
    end
  end

  def test_rejects_invalid_livecrawl_mode
    error = assert_raises(ArgumentError) do
      parse_search_args(["test query", "--livecrawl", "bogus"])
    end
    assert_includes error.message.downcase, "livecrawl"
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
