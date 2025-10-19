require "test_helper"

class FindSimilarResultTest < Minitest::Test
  def test_initialize_with_required_fields
    # Arrange
    results = [
      { "title" => "Similar Page", "url" => "https://example.com" }
    ]
    request_id = "abc123"

    # Act
    result = Exa::Resources::FindSimilarResult.new(
      results: results,
      request_id: request_id
    )

    # Assert
    assert_instance_of Exa::Resources::FindSimilarResult, result
    assert_equal results, result.results
    assert_equal request_id, result.request_id
  end

  def test_empty_returns_true_when_no_results
    # Arrange
    result = Exa::Resources::FindSimilarResult.new(
      results: [],
      request_id: "abc123"
    )

    # Act & Assert
    assert result.empty?
  end

  def test_first_returns_first_result
    # Arrange
    first_result = { "title" => "First Similar", "url" => "https://first.com" }
    second_result = { "title" => "Second Similar", "url" => "https://second.com" }
    result = Exa::Resources::FindSimilarResult.new(
      results: [first_result, second_result],
      request_id: "abc123"
    )

    # Act & Assert
    assert_equal first_result, result.first
  end

  def test_frozen_after_initialization
    # Arrange
    results = [{ "title" => "Test" }]
    result = Exa::Resources::FindSimilarResult.new(
      results: results,
      request_id: "abc123"
    )

    # Act & Assert
    assert_raises(FrozenError) do
      result.results = []
    end
  end

  def test_initialize_with_all_fields
    # Arrange
    results = [
      { "title" => "Similar Page", "url" => "https://example.com", "score" => 0.92 }
    ]
    request_id = "abc123"
    context = "This is a context string"
    cost_dollars = { "total" => 0.003 }

    # Act
    result = Exa::Resources::FindSimilarResult.new(
      results: results,
      request_id: request_id,
      context: context,
      cost_dollars: cost_dollars
    )

    # Assert
    assert_instance_of Exa::Resources::FindSimilarResult, result
    assert_equal results, result.results
    assert_equal request_id, result.request_id
    assert_equal context, result.context
    assert_equal cost_dollars, result.cost_dollars
  end
end
