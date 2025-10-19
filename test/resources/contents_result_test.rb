require "test_helper"
require_relative "../../lib/exa/resources/contents_result"

class ContentsResultTest < Minitest::Test
  def test_initialize_with_required_fields
    # Arrange
    results = [
      { "url" => "https://example.com", "text" => "Sample content" }
    ]
    request_id = "req_123"

    # Act
    contents_result = Exa::Resources::ContentsResult.new(
      results: results,
      request_id: request_id
    )

    # Assert
    assert_instance_of Exa::Resources::ContentsResult, contents_result
    assert_equal results, contents_result.results
    assert_equal request_id, contents_result.request_id
  end

  def test_empty_returns_true_when_no_results
    # Arrange
    contents_result = Exa::Resources::ContentsResult.new(
      results: [],
      request_id: "req_123"
    )

    # Act & Assert
    assert contents_result.empty?
  end

  def test_first_returns_first_result
    # Arrange
    first_result = { "url" => "https://first.com", "text" => "First content" }
    second_result = { "url" => "https://second.com", "text" => "Second content" }
    contents_result = Exa::Resources::ContentsResult.new(
      results: [first_result, second_result],
      request_id: "req_123"
    )

    # Act & Assert
    assert_equal first_result, contents_result.first
  end

  def test_statuses_returns_status_array
    # Arrange
    statuses = [
      { "id" => "https://example.com", "status" => "success" },
      { "id" => "https://other.com", "status" => "failed" }
    ]
    contents_result = Exa::Resources::ContentsResult.new(
      results: [],
      request_id: "req_123",
      statuses: statuses
    )

    # Act & Assert
    assert_equal statuses, contents_result.statuses
  end

  def test_frozen_after_initialization
    # Arrange
    results = [{ "url" => "https://example.com" }]
    contents_result = Exa::Resources::ContentsResult.new(
      results: results,
      request_id: "req_123"
    )

    # Act & Assert
    assert_raises(FrozenError) do
      contents_result.results = []
    end
  end

  def test_initialize_with_all_fields
    # Arrange
    results = [
      { "url" => "https://example.com", "text" => "Content here" }
    ]
    request_id = "req_abc"
    context = "This is context information"
    statuses = [
      { "id" => "https://example.com", "status" => "success" }
    ]
    cost_dollars = { "total" => 0.01 }

    # Act
    contents_result = Exa::Resources::ContentsResult.new(
      results: results,
      request_id: request_id,
      context: context,
      statuses: statuses,
      cost_dollars: cost_dollars
    )

    # Assert
    assert_instance_of Exa::Resources::ContentsResult, contents_result
    assert_equal results, contents_result.results
    assert_equal request_id, contents_result.request_id
    assert_equal context, contents_result.context
    assert_equal statuses, contents_result.statuses
    assert_equal cost_dollars, contents_result.cost_dollars
  end
end
