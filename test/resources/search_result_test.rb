require "test_helper"

class SearchResultTest < Minitest::Test
  def test_initialize_with_minimal_data
    # Arrange
    results = [
      { "title" => "Test Result", "url" => "https://example.com" }
    ]

    # Act
    search_result = Exa::Resources::SearchResult.new(
      results: results
    )

    # Assert
    assert_instance_of Exa::Resources::SearchResult, search_result
    assert_equal results, search_result.results
  end

  def test_initialize_with_all_fields
    # Arrange
    results = [
      { "title" => "Test Result", "url" => "https://example.com", "score" => 0.95 }
    ]
    request_id = "abc123"
    resolved_search_type = "neural"
    search_type = "auto"
    context = "This is a context string"
    cost_dollars = { "total" => 0.005 }

    # Act
    search_result = Exa::Resources::SearchResult.new(
      results: results,
      request_id: request_id,
      resolved_search_type: resolved_search_type,
      search_type: search_type,
      context: context,
      cost_dollars: cost_dollars
    )

    # Assert
    assert_instance_of Exa::Resources::SearchResult, search_result
    assert_equal results, search_result.results
    assert_equal request_id, search_result.request_id
    assert_equal resolved_search_type, search_result.resolved_search_type
    assert_equal search_type, search_result.search_type
    assert_equal context, search_result.context
    assert_equal cost_dollars, search_result.cost_dollars
  end

  def test_immutability
    # Arrange
    results = [{ "title" => "Test" }]
    search_result = Exa::Resources::SearchResult.new(results: results)

    # Act & Assert
    assert_raises(FrozenError) do
      search_result.results = []
    end
  end

  def test_empty_returns_true_when_results_empty
    # Arrange
    search_result = Exa::Resources::SearchResult.new(results: [])

    # Act & Assert
    assert search_result.empty?
  end

  def test_empty_returns_false_when_results_present
    # Arrange
    results = [{ "title" => "Test Result" }]
    search_result = Exa::Resources::SearchResult.new(results: results)

    # Act & Assert
    refute search_result.empty?
  end

  def test_first_returns_first_result
    # Arrange
    first_result = { "title" => "First Result", "url" => "https://first.com" }
    second_result = { "title" => "Second Result", "url" => "https://second.com" }
    search_result = Exa::Resources::SearchResult.new(
      results: [first_result, second_result]
    )

    # Act & Assert
    assert_equal first_result, search_result.first
  end

  def test_first_returns_nil_when_empty
    # Arrange
    search_result = Exa::Resources::SearchResult.new(results: [])

    # Act & Assert
    assert_nil search_result.first
  end

  def test_to_h_returns_hash_with_all_fields
    # Arrange
    results = [{ "title" => "Test" }]
    request_id = "abc123"
    resolved_search_type = "neural"
    search_type = "auto"
    context = "Test context"
    cost_dollars = { "total" => 0.005 }

    search_result = Exa::Resources::SearchResult.new(
      results: results,
      request_id: request_id,
      resolved_search_type: resolved_search_type,
      search_type: search_type,
      context: context,
      cost_dollars: cost_dollars
    )

    expected_hash = {
      results: results,
      request_id: request_id,
      resolved_search_type: resolved_search_type,
      search_type: search_type,
      context: context,
      cost_dollars: cost_dollars
    }

    # Act
    result_hash = search_result.to_h

    # Assert
    assert_equal expected_hash, result_hash
  end
end
