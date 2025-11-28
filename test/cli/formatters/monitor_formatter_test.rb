# frozen_string_literal: true

require "test_helper"

class MonitorFormatterTest < Minitest::Test
  def setup
    @monitor = Exa::Resources::Monitor.new(
      id: "mon_123",
      object: "monitor",
      status: "active",
      webset_id: "ws_abc",
      cadence: {"cron" => "0 0 * * *", "timezone" => "America/New_York"},
      behavior: {"type" => "search", "query" => "AI startups", "count" => 50},
      created_at: "2025-01-01T00:00:00Z",
      updated_at: "2025-01-01T01:00:00Z"
    )
  end

  def test_formats_monitor_as_json
    output = Exa::CLI::Formatters::MonitorFormatter.format(@monitor, "json")
    result = JSON.parse(output)

    assert_equal "mon_123", result["id"]
    assert_equal "monitor", result["object"]
    assert_equal "active", result["status"]
    assert_equal "ws_abc", result["webset_id"]
  end

  def test_formats_monitor_as_pretty
    output = Exa::CLI::Formatters::MonitorFormatter.format(@monitor, "pretty")
    result = JSON.parse(output)

    assert_equal "mon_123", result["id"]
    assert output.include?("\n"), "Pretty format should have newlines"
  end

  def test_formats_monitor_as_text
    output = Exa::CLI::Formatters::MonitorFormatter.format(@monitor, "text")

    assert_includes output, "mon_123"
    assert_includes output, "active"
    assert_includes output, "ws_abc"
  end

  def test_formats_collection_as_json
    collection = Exa::Resources::MonitorCollection.new(
      data: [
        {"id" => "mon_1", "status" => "active", "webset_id" => "ws_1"},
        {"id" => "mon_2", "status" => "paused", "webset_id" => "ws_2"}
      ],
      has_more: true,
      next_cursor: "cursor_abc"
    )

    output = Exa::CLI::Formatters::MonitorFormatter.format_collection(collection, "json")
    result = JSON.parse(output)

    assert_equal 2, result["data"].length
    assert_equal true, result["has_more"]
    assert_equal "cursor_abc", result["next_cursor"]
  end

  def test_formats_collection_as_pretty
    collection = Exa::Resources::MonitorCollection.new(
      data: [
        {"id" => "mon_1", "status" => "active"}
      ],
      has_more: false
    )

    output = Exa::CLI::Formatters::MonitorFormatter.format_collection(collection, "pretty")
    result = JSON.parse(output)

    assert_equal 1, result["data"].length
    assert output.include?("\n"), "Pretty format should have newlines"
  end

  def test_formats_collection_as_text
    collection = Exa::Resources::MonitorCollection.new(
      data: [
        {"id" => "mon_1", "status" => "active", "websetId" => "ws_1"},
        {"id" => "mon_2", "status" => "paused", "websetId" => "ws_2"}
      ],
      has_more: false
    )

    output = Exa::CLI::Formatters::MonitorFormatter.format_collection(collection, "text")

    assert_includes output, "mon_1"
    assert_includes output, "mon_2"
    assert_includes output, "active"
    assert_includes output, "paused"
  end

  def test_toon_format_returns_toon_string
    output = Exa::CLI::Formatters::MonitorFormatter.format(@monitor, "toon")

    assert_instance_of String, output
    assert_includes output, "mon_123"

    # TOON should be more compact than JSON
    json_output = Exa::CLI::Formatters::MonitorFormatter.format(@monitor, "json")
    assert output.length < json_output.length
  end

  def test_format_collection_toon_format_returns_toon_string
    collection = Exa::Resources::MonitorCollection.new(
      data: [
        {"id" => "mon_1", "status" => "active", "websetId" => "ws_1"},
        {"id" => "mon_2", "status" => "paused", "websetId" => "ws_2"}
      ],
      has_more: false
    )

    output = Exa::CLI::Formatters::MonitorFormatter.format_collection(collection, "toon")

    assert_instance_of String, output
    assert_includes output, "mon_1"

    # TOON should be more compact than JSON
    json_output = Exa::CLI::Formatters::MonitorFormatter.format_collection(collection, "json")
    assert output.length < json_output.length
  end
end
