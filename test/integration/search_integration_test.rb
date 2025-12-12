# frozen_string_literal: true

require "test_helper"

class SearchIntegrationTest < Minitest::Test
  def setup
    skip_unless_integration_enabled
  end

  # Test that we can make a real search request and get results back
  def test_search_returns_search_result_with_results
    VCR.use_cassette("search_ruby_programming") do
      # Use environment variable for API key, will be filtered in cassette
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      # Make a real search request
      result = client.search("Ruby programming language")

      # Verify we got a SearchResult object back
      assert_instance_of Exa::Resources::SearchResult, result

      # Verify results are not empty
      refute_empty result.results, "Expected search to return at least one result"
    end
  end

  # Test that SearchResult has the expected structure
  def test_search_result_has_expected_structure
    VCR.use_cassette("search_ruby_programming") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.search("Ruby programming language")

      # Verify SearchResult has all expected fields
      assert_respond_to result, :results
      assert_respond_to result, :request_id
      assert_respond_to result, :resolved_search_type
      assert_respond_to result, :search_type
      assert_respond_to result, :context
      assert_respond_to result, :cost_dollars

      # Verify helper methods
      assert_respond_to result, :empty?
      assert_respond_to result, :first

      # Verify results is an array
      assert_instance_of Array, result.results

      # Verify request_id is present (should be returned by API)
      refute_nil result.request_id, "Expected request_id to be present in response"
    end
  end

  # Test that individual results contain expected fields from the API
  def test_search_results_contain_expected_fields
    VCR.use_cassette("search_ruby_programming") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.search("Ruby programming language")

      # Get the first result
      first_result = result.first
      refute_nil first_result, "Expected at least one result"

      # Verify required fields are present (these are always returned by the API)
      assert first_result.key?("title"), "Expected result to have 'title' field"
      assert first_result.key?("url"), "Expected result to have 'url' field"
      assert first_result.key?("id"), "Expected result to have 'id' field"

      # Verify title is not empty
      refute_empty first_result["title"], "Expected title to not be empty"

      # Verify URL is a valid string
      assert_instance_of String, first_result["url"]
      assert first_result["url"].start_with?("http"), "Expected URL to start with http"

      # Verify ID is present
      assert_instance_of String, first_result["id"]

      # Optional fields exist in the hash but may be nil
      assert first_result.key?("author"), "Expected result to have 'author' field (may be nil)"

      # Some results may have publishedDate (not all do)
      # Just verify the first result has at least the core fields
    end
  end

  # Test date range filtering
  def test_search_with_date_range_filters
    VCR.use_cassette("search_with_date_filters") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      result = client.search(
        "AI research",
        start_published_date: "2025-01-01T00:00:00.000Z",
        end_published_date: "2025-12-31T23:59:59.999Z"
      )

      assert_instance_of Exa::Resources::SearchResult, result
      refute_empty result.results
    end
  end

  # Test text inclusion/exclusion filtering
  def test_search_with_text_filters
    VCR.use_cassette("search_with_text_filters") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      result = client.search(
        "machine learning",
        include_text: ["neural networks"],
        exclude_text: ["cryptocurrency"]
      )

      assert_instance_of Exa::Resources::SearchResult, result
    end
  end

  # Test full webpage text extraction
  def test_search_with_text_content_extraction
    VCR.use_cassette("search_with_text_extraction") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      result = client.search(
        "Ruby programming",
        text: {
          max_characters: 2000,
          include_html_tags: true
        }
      )

      assert_instance_of Exa::Resources::SearchResult, result
      refute_empty result.results

      # Verify text is present in results when requested
      first_result = result.first
      assert first_result.key?("text") || first_result.key?("content"),
             "Expected text extraction to be present in results"
    end
  end

  # Test AI summary generation
  def test_search_with_summary_generation
    VCR.use_cassette("search_with_summary") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      result = client.search(
        "climate change",
        summary: {
          query: "What are the main points about climate change?"
        }
      )

      assert_instance_of Exa::Resources::SearchResult, result
    end
  end

  # Test context string for RAG
  def test_search_with_context_for_rag
    VCR.use_cassette("search_with_context") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      result = client.search(
        "quantum computing",
        context: {
          max_characters: 5000
        }
      )

      assert_instance_of Exa::Resources::SearchResult, result
    end
  end

  # Test subpage crawling
  def test_search_with_subpage_crawling
    VCR.use_cassette("search_with_subpages") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      result = client.search(
        "JavaScript framework",
        subpages: 1,
        subpage_target: ["docs", "documentation", "guide"]
      )

      assert_instance_of Exa::Resources::SearchResult, result
    end
  end

  # Test links extraction
  def test_search_with_links_extraction
    VCR.use_cassette("search_with_links") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      result = client.search(
        "web development",
        extras: {
          links: 3,
          image_links: 2
        }
      )

      assert_instance_of Exa::Resources::SearchResult, result
    end
  end

  # Test comprehensive multi-feature search
  def test_search_with_multiple_features_combined
    VCR.use_cassette("search_comprehensive") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      result = client.search(
        "artificial intelligence",
        type: "neural",
        num_results: 5,
        start_published_date: "2025-01-01T00:00:00.000Z",
        end_published_date: "2025-12-31T23:59:59.999Z",
        include_text: ["machine learning"],
        text: {
          max_characters: 3000,
          include_html_tags: true
        },
        summary: {
          query: "What are the latest developments?"
        },
        context: {
          max_characters: 5000
        },
        subpages: 1,
        subpage_target: ["research", "papers"],
        extras: {
          links: 3,
          image_links: 2
        }
      )

      assert_instance_of Exa::Resources::SearchResult, result
      refute_empty result.results
      assert result.results.length <= 5
    end
  end

  # Test parameter conversion (snake_case to camelCase)
  def test_parameter_conversion_from_snake_case_to_camel_case
    VCR.use_cassette("search_with_crawl_dates") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      # Search with snake_case parameters (Ruby convention)
      result = client.search(
        "Ruby programming",
        start_crawl_date: "2025-01-01T00:00:00.000Z",
        end_crawl_date: "2025-12-31T23:59:59.999Z",
        text: true
      )

      assert_instance_of Exa::Resources::SearchResult, result
    end
  end
end
