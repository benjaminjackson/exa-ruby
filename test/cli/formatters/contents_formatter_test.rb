# frozen_string_literal: true

require "test_helper"
require_relative "../../../lib/exa/cli/formatters/contents_formatter"

class Exa::CLI::Formatters::ContentsFormatterTest < Minitest::Test
  def test_json_format_returns_json_string
    result = create_contents_result
    output = Exa::CLI::Formatters::ContentsFormatter.format(result, "json")

    # Verify it's valid JSON
    parsed = JSON.parse(output)
    assert_equal 2, parsed["results"].length
    assert_equal "Example Title 1", parsed["results"][0]["title"]
    assert_equal "https://example.com/1", parsed["results"][0]["url"]
  end

  def test_pretty_format_shows_sections
    result = create_contents_result
    output = Exa::CLI::Formatters::ContentsFormatter.format(result, "pretty")

    # Verify it includes expected content
    assert_includes output, "Content 1"
    assert_includes output, "https://example.com/1"
    assert_includes output, "Example Title 1"
    assert_includes output, "This is the text content"

    assert_includes output, "Content 2"
    assert_includes output, "https://example.com/2"
    assert_includes output, "Example Title 2"
  end

  def test_default_format_is_json
    result = create_contents_result
    output = Exa::CLI::Formatters::ContentsFormatter.format(result, nil)

    # Should default to JSON
    parsed = JSON.parse(output)
    assert parsed["results"]
  end

  def test_pretty_format_truncates_long_text
    # Create a result with very long text
    long_text = "a" * 1000
    result = Exa::Resources::ContentsResult.new(
      results: [
        {
          "url" => "https://example.com",
          "title" => "Long Content",
          "text" => long_text
        }
      ]
    )

    output = Exa::CLI::Formatters::ContentsFormatter.format(result, "pretty")

    # Should truncate and add "..."
    assert_includes output, "..."
    # Should not include the full 1000 characters
    refute_includes output, long_text
  end

  def test_text_format_shows_url_and_text
    result = create_contents_result
    output = Exa::CLI::Formatters::ContentsFormatter.format(result, "text")

    # Verify it includes URLs and text
    assert_includes output, "https://example.com/1"
    assert_includes output, "This is the text content for the first example."
    assert_includes output, "https://example.com/2"
    assert_includes output, "This is the text content for the second example."
  end

  private

  def create_contents_result
    Exa::Resources::ContentsResult.new(
      results: [
        {
          "title" => "Example Title 1",
          "url" => "https://example.com/1",
          "id" => "id1",
          "text" => "This is the text content for the first example."
        },
        {
          "title" => "Example Title 2",
          "url" => "https://example.com/2",
          "id" => "id2",
          "text" => "This is the text content for the second example."
        }
      ],
      request_id: "test-request-id",
      cost_dollars: 0.001
    )
  end
end
