# frozen_string_literal: true

require "test_helper"

class ContextIntegrationTest < Minitest::Test
  def test_context_returns_context_result_with_code_snippets
    VCR.use_cassette("context_react_hooks") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"] || "test_api_key")

      result = client.context("how to use React hooks for state management", tokensNum: 5000)

      assert_instance_of Exa::Resources::ContextResult, result
      refute_nil result.response
      refute_empty result.response
      assert_equal "how to use React hooks for state management", result.query
      refute_nil result.request_id
    end
  end

  def test_context_result_has_expected_structure
    VCR.use_cassette("context_react_hooks") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"] || "test_api_key")

      result = client.context("how to use React hooks for state management", tokensNum: 5000)

      # Verify all expected methods respond
      assert_respond_to result, :request_id
      assert_respond_to result, :query
      assert_respond_to result, :response
      assert_respond_to result, :results_count
      assert_respond_to result, :cost_dollars
      assert_respond_to result, :search_time
      assert_respond_to result, :output_tokens

      # Verify field types
      assert_instance_of String, result.request_id
      assert_instance_of String, result.query
      assert_instance_of String, result.response
      assert_instance_of Integer, result.results_count
      assert result.results_count > 0
      assert_instance_of Integer, result.output_tokens
    end
  end

  def test_context_with_specific_token_limit
    VCR.use_cassette("context_with_token_limit") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"] || "test_api_key")

      result = client.context("Express middleware", tokensNum: 3000)

      assert_instance_of Exa::Resources::ContextResult, result
      refute_nil result.response
      assert result.output_tokens > 0
      assert result.output_tokens <= 3000
    end
  end

  def test_context_with_dynamic_tokens
    VCR.use_cassette("context_dynamic_tokens") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"] || "test_api_key")

      result = client.context("pandas dataframe filtering", tokensNum: "dynamic")

      assert_instance_of Exa::Resources::ContextResult, result
      refute_nil result.response
      refute_empty result.response
      assert_instance_of Integer, result.output_tokens
    end
  end
end
