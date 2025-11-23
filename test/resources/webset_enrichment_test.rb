# frozen_string_literal: true

require "test_helper"

class WebsetEnrichmentTest < Minitest::Test
  def test_initializes_with_all_fields
    enrichment = Exa::Resources::WebsetEnrichment.new(
      id: "enrich_123",
      object: "webset_enrichment",
      status: "pending",
      webset_id: "ws_abc",
      title: "Email Extraction",
      description: "Extract email addresses",
      format: "text",
      options: [{ "label" => "Personal" }, { "label" => "Work" }],
      instructions: "Find all contact emails",
      metadata: { "priority" => "high" },
      created_at: "2024-01-15T10:00:00Z",
      updated_at: "2024-01-15T10:00:00Z"
    )

    assert_equal "enrich_123", enrichment.id
    assert_equal "webset_enrichment", enrichment.object
    assert_equal "pending", enrichment.status
    assert_equal "ws_abc", enrichment.webset_id
    assert_equal "Email Extraction", enrichment.title
    assert_equal "Extract email addresses", enrichment.description
    assert_equal "text", enrichment.format
    assert_equal [{ "label" => "Personal" }, { "label" => "Work" }], enrichment.options
    assert_equal "Find all contact emails", enrichment.instructions
    assert_equal({ "priority" => "high" }, enrichment.metadata)
    assert_equal "2024-01-15T10:00:00Z", enrichment.created_at
    assert_equal "2024-01-15T10:00:00Z", enrichment.updated_at
  end

  def test_to_h_returns_all_fields_as_hash
    enrichment = Exa::Resources::WebsetEnrichment.new(
      id: "enrich_123",
      object: "webset_enrichment",
      status: "completed",
      webset_id: "ws_abc",
      title: "Test Title",
      description: "Test description",
      format: "text",
      options: [{ "label" => "Option 1" }],
      instructions: "Test instructions",
      metadata: { "key" => "value" },
      created_at: "2024-01-15T10:00:00Z",
      updated_at: "2024-01-15T10:00:00Z"
    )

    hash = enrichment.to_h

    assert_equal "enrich_123", hash[:id]
    assert_equal "webset_enrichment", hash[:object]
    assert_equal "completed", hash[:status]
    assert_equal "ws_abc", hash[:webset_id]
    assert_equal "Test Title", hash[:title]
    assert_equal "Test description", hash[:description]
    assert_equal "text", hash[:format]
    assert_equal [{ "label" => "Option 1" }], hash[:options]
    assert_equal "Test instructions", hash[:instructions]
    assert_equal({ "key" => "value" }, hash[:metadata])
    assert_equal "2024-01-15T10:00:00Z", hash[:created_at]
    assert_equal "2024-01-15T10:00:00Z", hash[:updated_at]
  end

  def test_is_frozen_after_initialization
    enrichment = Exa::Resources::WebsetEnrichment.new(
      id: "enrich_123",
      object: "webset_enrichment",
      status: "pending"
    )

    assert enrichment.frozen?
  end
end
