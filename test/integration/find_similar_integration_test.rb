# frozen_string_literal: true

require "test_helper"

# NOTE: These integration tests will FAIL until Task C (Wire client method) is complete.
# The client.find_similar method does not exist yet - that's expected!
# This file defines the integration test contract for the FindSimilar service.

class FindSimilarIntegrationTest < Minitest::Test
  def setup
    skip_unless_integration_enabled
  end
  # Test that we can make a real find_similar request and get results back
  def test_find_similar_returns_result_with_results
    VCR.use_cassette("find_similar_llama_paper") do
      # Use environment variable for API key, will be filtered in cassette
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      # Make a real find_similar request using the Llama 2 paper
      result = client.find_similar("https://arxiv.org/abs/2307.06435")

      # Verify we got a FindSimilarResult object back
      assert_instance_of Exa::Resources::FindSimilarResult, result

      # Verify results are not empty
      refute_empty result.results, "Expected find_similar to return at least one result"
    end
  end

  # Test that FindSimilarResult has the expected structure
  def test_find_similar_result_has_expected_structure
    VCR.use_cassette("find_similar_llama_paper") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.find_similar("https://arxiv.org/abs/2307.06435")

      # Verify FindSimilarResult has all expected fields
      assert_respond_to result, :results
      assert_respond_to result, :request_id
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
  def test_find_similar_results_contain_expected_fields
    VCR.use_cassette("find_similar_llama_paper") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.find_similar("https://arxiv.org/abs/2307.06435")

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
    end
  end
end
