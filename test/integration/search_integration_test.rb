# frozen_string_literal: true

require "test_helper"

class SearchIntegrationTest < Minitest::Test
  # Test that we can make a real search request and get results back
  def test_search_returns_search_result_with_results
    VCR.use_cassette("search_ruby_programming") do
      # Use environment variable for API key, will be filtered in cassette
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"] || "test_api_key")

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
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"] || "test_api_key")
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
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"] || "test_api_key")
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
end
