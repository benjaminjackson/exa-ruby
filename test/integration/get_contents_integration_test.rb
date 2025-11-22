# frozen_string_literal: true

require "test_helper"

# NOTE: These tests will fail until Task C adds the get_contents method to Client
# This is expected! We're creating the integration tests first (TDD approach).
class GetContentsIntegrationTest < Minitest::Test
  # Test that we can retrieve contents for a URL
  def test_get_contents_returns_result_with_content
    VCR.use_cassette("get_contents_llama_paper") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      # Request contents for the LLaMA paper
      result = client.get_contents(["https://arxiv.org/abs/2307.06435"])

      # Verify we got a ContentsResult object back
      assert_instance_of Exa::Resources::ContentsResult, result

      # Verify results are not empty
      refute_empty result.results, "Expected get_contents to return at least one result"
    end
  end

  # Test that ContentsResult has the expected structure
  def test_contents_result_has_expected_structure
    VCR.use_cassette("get_contents_llama_paper") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.get_contents(["https://arxiv.org/abs/2307.06435"])

      # Verify ContentsResult has all expected fields
      assert_respond_to result, :results
      assert_respond_to result, :request_id
      assert_respond_to result, :context
      assert_respond_to result, :statuses
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

  # Test that individual content results contain expected fields
  def test_contents_results_contain_text
    VCR.use_cassette("get_contents_llama_paper") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.get_contents(["https://arxiv.org/abs/2307.06435"])

      # Get the first result
      first_result = result.first
      refute_nil first_result, "Expected at least one result"

      # Verify required fields are present
      assert first_result.key?("title"), "Expected result to have 'title' field"
      assert first_result.key?("url"), "Expected result to have 'url' field"
      assert first_result.key?("id"), "Expected result to have 'id' field"

      # Verify text field if present (depends on request options)
      if first_result.key?("text")
        assert_instance_of String, first_result["text"]
        refute_empty first_result["text"], "Expected text to not be empty when present"
      end
    end
  end

  # Test that get_contents works with text options
  def test_get_contents_with_text_options
    VCR.use_cassette("get_contents_with_options") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      # Request contents with text options
      result = client.get_contents(
        ["https://arxiv.org/abs/2307.06435"],
        text: { maxCharacters: 1000 }
      )

      # Verify response includes text
      first_result = result.first
      refute_nil first_result, "Expected at least one result"

      # When text options are specified, text should be present
      assert first_result.key?("text"), "Expected text field when text options provided"
      assert_instance_of String, first_result["text"]
    end
  end

  # Test that ContentsResult includes statuses array
  def test_contents_result_includes_statuses
    VCR.use_cassette("get_contents_llama_paper") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.get_contents(["https://arxiv.org/abs/2307.06435"])

      # Verify statuses array exists
      refute_nil result.statuses, "Expected statuses to be present"
      assert_instance_of Array, result.statuses

      # Each status should have id and status fields
      result.statuses.each do |status|
        assert status.key?("id"), "Expected status to have 'id' field"
        assert status.key?("status"), "Expected status to have 'status' field"
      end
    end
  end
end
