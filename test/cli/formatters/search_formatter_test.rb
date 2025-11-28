# frozen_string_literal: true

require "test_helper"

class Exa::CLI::Formatters::SearchFormatterTest < Minitest::Test
  def test_json_format_returns_json_string
    result = create_search_result
    output = Exa::CLI::Formatters::SearchFormatter.format(result, "json")

    # Verify it's valid JSON
    parsed = JSON.parse(output)
    assert_equal 2, parsed["results"].length
    assert_equal "Example Title 1", parsed["results"][0]["title"]
    assert_equal "https://example.com/1", parsed["results"][0]["url"]
  end

  def test_pretty_format_shows_title_url_score
    result = create_search_result
    output = Exa::CLI::Formatters::SearchFormatter.format(result, "pretty")

    # Verify it includes expected content
    assert_includes output, "Result 1"
    assert_includes output, "Example Title 1"
    assert_includes output, "https://example.com/1"
    assert_includes output, "Score:"
    assert_includes output, "0.95"

    assert_includes output, "Result 2"
    assert_includes output, "Example Title 2"
    assert_includes output, "https://example.com/2"
    assert_includes output, "0.87"
  end

  def test_text_format_shows_title_and_url
    result = create_search_result
    output = Exa::CLI::Formatters::SearchFormatter.format(result, "text")

    # Verify it includes expected content
    assert_includes output, "Example Title 1"
    assert_includes output, "https://example.com/1"
    assert_includes output, "Example Title 2"
    assert_includes output, "https://example.com/2"
  end

  def test_default_format_is_json
    result = create_search_result
    output = Exa::CLI::Formatters::SearchFormatter.format(result, nil)

    # Should default to JSON
    parsed = JSON.parse(output)
    assert parsed["results"]
  end

  def test_toon_format_returns_toon_string
    result = create_search_result
    output = Exa::CLI::Formatters::SearchFormatter.format(result, "toon")

    assert_instance_of String, output
    assert_includes output, "Example Title 1"
    assert_includes output, "https://example.com/1"

    # TOON should be more compact than JSON
    json_output = Exa::CLI::Formatters::SearchFormatter.format(result, "json")
    assert output.length < json_output.length
  end

  private

  def create_search_result
    Exa::Resources::SearchResult.new(
      results: [
        {
          "title" => "Example Title 1",
          "url" => "https://example.com/1",
          "id" => "id1",
          "score" => 0.95,
          "published_date" => "2024-01-01"
        },
        {
          "title" => "Example Title 2",
          "url" => "https://example.com/2",
          "id" => "id2",
          "score" => 0.87,
          "published_date" => "2024-01-02"
        }
      ],
      request_id: "test-request-id",
      resolved_search_type: "fast",
      search_type: "fast",
      context: nil,
      cost_dollars: 0.001
    )
  end
end
