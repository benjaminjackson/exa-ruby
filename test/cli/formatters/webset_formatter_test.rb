# frozen_string_literal: true

require "test_helper"

class WebsetFormatterTest < Minitest::Test
  def setup
    @webset = Exa::Resources::Webset.new(
      id: "ws_123",
      object: "webset",
      status: "idle",
      created_at: "2025-01-01T00:00:00Z",
      updated_at: "2025-01-01T00:00:00Z"
    )
  end

  def test_formats_webset_as_json
    output = Exa::CLI::Formatters::WebsetFormatter.format(@webset, "json")
    result = JSON.parse(output)

    assert_equal "ws_123", result["id"]
    assert_equal "webset", result["object"]
    assert_equal "idle", result["status"]
  end

  def test_formats_webset_as_pretty
    output = Exa::CLI::Formatters::WebsetFormatter.format(@webset, "pretty")
    result = JSON.parse(output)

    assert_equal "ws_123", result["id"]
    assert output.include?("\n"), "Pretty format should have newlines"
  end

  def test_formats_webset_as_text
    output = Exa::CLI::Formatters::WebsetFormatter.format(@webset, "text")

    assert_includes output, "ws_123"
    assert_includes output, "idle"
  end

  def test_toon_format_returns_toon_string
    output = Exa::CLI::Formatters::WebsetFormatter.format(@webset, "toon")

    assert_instance_of String, output
    assert_includes output, "ws_123"

    # TOON should be more compact than JSON
    json_output = Exa::CLI::Formatters::WebsetFormatter.format(@webset, "json")
    assert output.length < json_output.length
  end

  def test_format_collection_toon_format_returns_toon_string
    collection = Exa::Resources::WebsetCollection.new(
      data: [@webset.to_h],
      has_more: false,
      next_cursor: nil
    )

    output = Exa::CLI::Formatters::WebsetFormatter.format_collection(collection, "toon")

    assert_instance_of String, output
    assert_includes output, "ws_123"

    # TOON should be more compact than JSON
    json_output = Exa::CLI::Formatters::WebsetFormatter.format_collection(collection, "json")
    assert output.length < json_output.length
  end
end
