require "test_helper"

class ContextResultTest < Minitest::Test
  def test_initialize_with_all_fields
    # Arrange
    request_id = "81c4198a1d6794503b52134fd77159e2"
    query = "how to use React hooks for state management"
    response = "## State Management with useState Hook...\n```javascript\n...\n```"
    results_count = 502
    cost_dollars = "{\"total\":1,\"search\":{\"neural\":1}}"
    search_time = 3112.290825000033
    output_tokens = 4805

    # Act
    context_result = Exa::Resources::ContextResult.new(
      request_id: request_id,
      query: query,
      response: response,
      results_count: results_count,
      cost_dollars: cost_dollars,
      search_time: search_time,
      output_tokens: output_tokens
    )

    # Assert
    assert_instance_of Exa::Resources::ContextResult, context_result
    assert_equal request_id, context_result.request_id
    assert_equal query, context_result.query
    assert_equal response, context_result.response
    assert_equal results_count, context_result.results_count
    assert_equal cost_dollars, context_result.cost_dollars
    assert_equal search_time, context_result.search_time
    assert_equal output_tokens, context_result.output_tokens
  end

  def test_initialize_with_only_required_fields
    # Arrange
    request_id = "abc123"
    query = "Express middleware"
    response = "Code examples..."

    # Act
    context_result = Exa::Resources::ContextResult.new(
      request_id: request_id,
      query: query,
      response: response
    )

    # Assert
    assert_instance_of Exa::Resources::ContextResult, context_result
    assert_equal request_id, context_result.request_id
    assert_equal query, context_result.query
    assert_equal response, context_result.response
    assert_nil context_result.results_count
    assert_nil context_result.cost_dollars
    assert_nil context_result.search_time
    assert_nil context_result.output_tokens
  end

  def test_immutability
    # Arrange
    context_result = Exa::Resources::ContextResult.new(
      request_id: "abc123",
      query: "test",
      response: "code"
    )

    # Act & Assert
    assert_raises(FrozenError) do
      context_result.request_id = "changed"
    end

    assert_raises(FrozenError) do
      context_result.query = "changed"
    end
  end

  def test_to_h_returns_hash_with_all_fields
    # Arrange
    request_id = "81c4198a1d6794503b52134fd77159e2"
    query = "how to use React hooks for state management"
    response = "## State Management with useState Hook...\n```javascript\n...\n```"
    results_count = 502
    cost_dollars = "{\"total\":1,\"search\":{\"neural\":1}}"
    search_time = 3112.290825000033
    output_tokens = 4805

    context_result = Exa::Resources::ContextResult.new(
      request_id: request_id,
      query: query,
      response: response,
      results_count: results_count,
      cost_dollars: cost_dollars,
      search_time: search_time,
      output_tokens: output_tokens
    )

    expected_hash = {
      request_id: request_id,
      query: query,
      response: response,
      results_count: results_count,
      cost_dollars: cost_dollars,
      search_time: search_time,
      output_tokens: output_tokens
    }

    # Act
    result_hash = context_result.to_h

    # Assert
    assert_equal expected_hash, result_hash
  end

  def test_to_h_includes_nil_fields
    # Arrange
    context_result = Exa::Resources::ContextResult.new(
      request_id: "abc123",
      query: "test",
      response: "code"
    )

    # Act
    result_hash = context_result.to_h

    # Assert
    assert_includes result_hash.keys, :request_id
    assert_includes result_hash.keys, :query
    assert_includes result_hash.keys, :response
    assert_includes result_hash.keys, :results_count
    assert_includes result_hash.keys, :cost_dollars
    assert_includes result_hash.keys, :search_time
    assert_includes result_hash.keys, :output_tokens

    assert_equal "abc123", result_hash[:request_id]
    assert_equal "test", result_hash[:query]
    assert_equal "code", result_hash[:response]
    assert_nil result_hash[:results_count]
    assert_nil result_hash[:cost_dollars]
    assert_nil result_hash[:search_time]
    assert_nil result_hash[:output_tokens]
  end
end
