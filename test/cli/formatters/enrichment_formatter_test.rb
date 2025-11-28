# frozen_string_literal: true

require "test_helper"

class EnrichmentFormatterTest < Minitest::Test
  def setup
    @enrichment = Exa::Resources::WebsetEnrichment.new(
      id: "enr_123",
      object: "enrichment",
      status: "completed",
      webset_id: "ws_123",
      title: "Company Size",
      description: "Extract company size information",
      format: "options",
      options: [{"label" => "1-10"}, {"label" => "11-50"}],
      created_at: "2025-01-01T00:00:00Z",
      updated_at: "2025-01-01T01:00:00Z"
    )
  end

  def test_formats_enrichment_as_json
    output = Exa::CLI::Formatters::EnrichmentFormatter.format(@enrichment, "json")
    result = JSON.parse(output)

    assert_equal "enr_123", result["id"]
    assert_equal "enrichment", result["object"]
    assert_equal "completed", result["status"]
    assert_equal "ws_123", result["webset_id"]
  end

  def test_formats_enrichment_as_pretty
    output = Exa::CLI::Formatters::EnrichmentFormatter.format(@enrichment, "pretty")
    result = JSON.parse(output)

    assert_equal "enr_123", result["id"]
    assert output.include?("\n"), "Pretty format should have newlines"
  end

  def test_formats_enrichment_as_text
    output = Exa::CLI::Formatters::EnrichmentFormatter.format(@enrichment, "text")

    assert_includes output, "enr_123"
    assert_includes output, "completed"
    assert_includes output, "Company Size"
    assert_includes output, "Extract company size information"
  end

  def test_formats_collection_as_json
    collection = Exa::Resources::WebsetEnrichmentCollection.new(
      data: [
        {"id" => "enr_1", "status" => "completed"},
        {"id" => "enr_2", "status" => "running"}
      ]
    )

    output = Exa::CLI::Formatters::EnrichmentFormatter.format_collection(collection, "json")
    result = JSON.parse(output)

    assert_equal 2, result["data"].length
  end

  def test_formats_collection_as_text
    collection = Exa::Resources::WebsetEnrichmentCollection.new(
      data: [
        {"id" => "enr_1", "status" => "completed", "title" => "Size"},
        {"id" => "enr_2", "status" => "running", "title" => "Industry"}
      ]
    )

    output = Exa::CLI::Formatters::EnrichmentFormatter.format_collection(collection, "text")

    assert_includes output, "enr_1"
    assert_includes output, "enr_2"
    assert_includes output, "completed"
    assert_includes output, "running"
  end

  def test_toon_format_returns_toon_string
    output = Exa::CLI::Formatters::EnrichmentFormatter.format(@enrichment, "toon")

    assert_instance_of String, output
    assert_includes output, "enr_123"

    # TOON should be more compact than JSON
    json_output = Exa::CLI::Formatters::EnrichmentFormatter.format(@enrichment, "json")
    assert output.length < json_output.length
  end

  def test_format_collection_toon_format_returns_toon_string
    collection = Exa::Resources::WebsetEnrichmentCollection.new(
      data: [
        {"id" => "enr_1", "status" => "completed", "title" => "Size"},
        {"id" => "enr_2", "status" => "running", "title" => "Industry"}
      ]
    )

    output = Exa::CLI::Formatters::EnrichmentFormatter.format_collection(collection, "toon")

    assert_instance_of String, output
    assert_includes output, "enr_1"

    # TOON should be more compact than JSON
    json_output = Exa::CLI::Formatters::EnrichmentFormatter.format_collection(collection, "json")
    assert output.length < json_output.length
  end
end
