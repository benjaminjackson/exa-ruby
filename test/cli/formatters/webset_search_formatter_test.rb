# frozen_string_literal: true

require "test_helper"

class Exa::CLI::Formatters::WebsetSearchFormatterTest < Minitest::Test
  def test_json_format_returns_json_string
    search = create_webset_search
    output = Exa::CLI::Formatters::WebsetSearchFormatter.format(search, "json")

    # Verify it's valid JSON
    parsed = JSON.parse(output)
    assert_equal "ws_search_123", parsed["id"]
    assert_equal "running", parsed["status"]
    assert_equal "AI startups", parsed["query"]
  end

  def test_pretty_format_shows_search_metadata
    search = create_webset_search
    output = Exa::CLI::Formatters::WebsetSearchFormatter.format(search, "pretty")

    # Verify it includes expected metadata
    assert_includes output, "Search ID:       ws_search_123"
    assert_includes output, "Status:          running"
    assert_includes output, "Query:           AI startups"
    assert_includes output, "Behavior:        override"
    assert_includes output, "Created:         2024-01-01T12:00:00Z"
  end

  def test_pretty_format_excludes_results_property
    search = create_webset_search
    output = Exa::CLI::Formatters::WebsetSearchFormatter.format(search, "pretty")

    # Verify .results is not accessed
    refute_includes output, "results"
  end

  def test_text_format_shows_key_fields
    search = create_webset_search
    output = Exa::CLI::Formatters::WebsetSearchFormatter.format(search, "text")

    # Verify it includes key fields
    assert_includes output, "ID: ws_search_123"
    assert_includes output, "Status: running"
    assert_includes output, "Query: AI startups"
    assert_includes output, "Behavior: override"
  end

  def test_default_format_is_json
    search = create_webset_search
    output = Exa::CLI::Formatters::WebsetSearchFormatter.format(search, nil)

    # Should default to JSON
    parsed = JSON.parse(output)
    assert_equal "ws_search_123", parsed["id"]
  end

  def test_toon_format_returns_toon_string
    search = create_webset_search
    output = Exa::CLI::Formatters::WebsetSearchFormatter.format(search, "toon")

    assert_instance_of String, output
    assert_includes output, "ws_search_123"
    assert_includes output, "AI startups"

    # TOON should be more compact than JSON
    json_output = Exa::CLI::Formatters::WebsetSearchFormatter.format(search, "json")
    assert output.length < json_output.length
  end

  def test_pretty_format_with_canceled_search
    search = create_canceled_webset_search
    output = Exa::CLI::Formatters::WebsetSearchFormatter.format(search, "pretty")

    assert_includes output, "Status:          canceled"
    assert_includes output, "Canceled:        2024-01-01T13:00:00Z"
    assert_includes output, "Cancel Reason:   User requested cancellation"
  end

  def test_pretty_format_with_custom_entity
    search = create_webset_search_with_entity
    output = Exa::CLI::Formatters::WebsetSearchFormatter.format(search, "pretty")

    assert_includes output, "Entity Type:     custom"
  end

  def test_pretty_format_handles_nil_progress
    search = create_webset_search_without_progress
    # Ensure progress is nil
    assert_nil search.progress

    output = Exa::CLI::Formatters::WebsetSearchFormatter.format(search, "pretty")
    # Should not fail and should have valid output
    assert_includes output, "Query:"
  end

  private

  def create_webset_search
    Exa::Resources::WebsetSearch.new(
      id: "ws_search_123",
      object: "webset.search",
      status: "running",
      webset_id: "ws_456",
      query: "AI startups",
      entity: { "type" => "company" },
      criteria: nil,
      count: 50,
      behavior: "override",
      exclude: nil,
      scope: nil,
      progress: 25,
      recall: false,
      metadata: nil,
      canceled_at: nil,
      canceled_reason: nil,
      created_at: "2024-01-01T12:00:00Z",
      updated_at: "2024-01-01T12:30:00Z"
    )
  end

  def create_canceled_webset_search
    Exa::Resources::WebsetSearch.new(
      id: "ws_search_789",
      object: "webset.search",
      status: "canceled",
      webset_id: "ws_456",
      query: "tech companies",
      entity: nil,
      criteria: nil,
      count: nil,
      behavior: "override",
      exclude: nil,
      scope: nil,
      progress: 50,
      recall: false,
      metadata: nil,
      canceled_at: "2024-01-01T13:00:00Z",
      canceled_reason: "User requested cancellation",
      created_at: "2024-01-01T12:00:00Z",
      updated_at: "2024-01-01T13:00:00Z"
    )
  end

  def create_webset_search_with_entity
    Exa::Resources::WebsetSearch.new(
      id: "ws_search_custom",
      object: "webset.search",
      status: "completed",
      webset_id: "ws_456",
      query: "vintage cars",
      entity: { "type" => "custom", "description" => "vintage cars" },
      criteria: nil,
      count: 20,
      behavior: "append",
      exclude: nil,
      scope: nil,
      progress: 100,
      recall: false,
      metadata: nil,
      canceled_at: nil,
      canceled_reason: nil,
      created_at: "2024-01-01T12:00:00Z",
      updated_at: "2024-01-01T12:45:00Z"
    )
  end

  def create_webset_search_without_progress
    Exa::Resources::WebsetSearch.new(
      id: "ws_search_no_progress",
      object: "webset.search",
      status: "created",
      webset_id: "ws_456",
      query: "test query",
      entity: nil,
      criteria: nil,
      count: nil,
      behavior: "override",
      exclude: nil,
      scope: nil,
      progress: nil,
      recall: false,
      metadata: nil,
      canceled_at: nil,
      canceled_reason: nil,
      created_at: "2024-01-01T12:00:00Z",
      updated_at: "2024-01-01T12:00:00Z"
    )
  end
end
