# frozen_string_literal: true

require "test_helper"

class MonitorRunFormatterTest < Minitest::Test
  def setup
    @monitor_run = Exa::Resources::MonitorRun.new(
      id: "run_123",
      object: "monitor_run",
      monitor_id: "mon_abc",
      status: "completed",
      created_at: "2025-01-01T00:00:00Z",
      updated_at: "2025-01-01T01:00:00Z",
      completed_at: "2025-01-01T01:00:00Z",
      failed_at: nil,
      failed_reason: nil
    )
  end

  def test_formats_monitor_run_as_json
    output = Exa::CLI::Formatters::MonitorRunFormatter.format(@monitor_run, "json")
    result = JSON.parse(output)

    assert_equal "run_123", result["id"]
    assert_equal "monitor_run", result["object"]
    assert_equal "mon_abc", result["monitor_id"]
    assert_equal "completed", result["status"]
  end

  def test_formats_monitor_run_as_pretty
    output = Exa::CLI::Formatters::MonitorRunFormatter.format(@monitor_run, "pretty")
    result = JSON.parse(output)

    assert_equal "run_123", result["id"]
    assert output.include?("\n"), "Pretty format should have newlines"
  end

  def test_formats_monitor_run_as_text
    output = Exa::CLI::Formatters::MonitorRunFormatter.format(@monitor_run, "text")

    assert_includes output, "run_123"
    assert_includes output, "completed"
    assert_includes output, "mon_abc"
  end

  def test_formats_collection_as_json
    collection = Exa::Resources::MonitorRunCollection.new(
      data: [
        {"id" => "run_1", "status" => "completed", "monitorId" => "mon_1"},
        {"id" => "run_2", "status" => "failed", "monitorId" => "mon_1"}
      ],
      has_more: true,
      next_cursor: "cursor_xyz"
    )

    output = Exa::CLI::Formatters::MonitorRunFormatter.format_collection(collection, "json")
    result = JSON.parse(output)

    assert_equal 2, result["data"].length
    assert_equal true, result["has_more"]
    assert_equal "cursor_xyz", result["next_cursor"]
  end

  def test_formats_collection_as_pretty
    collection = Exa::Resources::MonitorRunCollection.new(
      data: [
        {"id" => "run_1", "status" => "completed"}
      ],
      has_more: false
    )

    output = Exa::CLI::Formatters::MonitorRunFormatter.format_collection(collection, "pretty")
    result = JSON.parse(output)

    assert_equal 1, result["data"].length
    assert output.include?("\n"), "Pretty format should have newlines"
  end

  def test_formats_collection_as_text
    collection = Exa::Resources::MonitorRunCollection.new(
      data: [
        {"id" => "run_1", "status" => "completed", "completedAt" => "2025-01-01T01:00:00Z"},
        {"id" => "run_2", "status" => "failed", "failedReason" => "timeout"}
      ],
      has_more: false
    )

    output = Exa::CLI::Formatters::MonitorRunFormatter.format_collection(collection, "text")

    assert_includes output, "run_1"
    assert_includes output, "run_2"
    assert_includes output, "completed"
    assert_includes output, "failed"
  end

  def test_toon_format_returns_toon_string
    output = Exa::CLI::Formatters::MonitorRunFormatter.format(@monitor_run, "toon")

    assert_instance_of String, output
    assert_includes output, "run_123"

    # TOON should be more compact than JSON
    json_output = Exa::CLI::Formatters::MonitorRunFormatter.format(@monitor_run, "json")
    assert output.length < json_output.length
  end

  def test_format_collection_toon_format_returns_toon_string
    collection = Exa::Resources::MonitorRunCollection.new(
      data: [
        {"id" => "run_1", "status" => "completed", "completedAt" => "2025-01-01T01:00:00Z"},
        {"id" => "run_2", "status" => "failed", "failedReason" => "timeout"}
      ],
      has_more: false
    )

    output = Exa::CLI::Formatters::MonitorRunFormatter.format_collection(collection, "toon")

    assert_instance_of String, output
    assert_includes output, "run_1"

    # TOON should be more compact than or equal to JSON
    json_output = Exa::CLI::Formatters::MonitorRunFormatter.format_collection(collection, "json")
    assert output.length <= json_output.length
  end
end
