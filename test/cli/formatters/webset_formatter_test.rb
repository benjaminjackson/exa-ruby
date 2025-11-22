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
end
