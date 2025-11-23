# frozen_string_literal: true

require "test_helper"

class WebsetsCreateEnrichmentTest < Minitest::Test
  def setup
    @connection = Minitest::Mock.new
  end

  def test_creates_enrichment_with_all_parameters
    response_body = {
      "id" => "enrich_abc123",
      "object" => "webset_enrichment",
      "status" => "pending",
      "websetId" => "ws_test",
      "title" => "Email Extraction",
      "description" => "Extract all email addresses",
      "format" => "text",
      "options" => [
        { "label" => "Personal" },
        { "label" => "Work" }
      ],
      "instructions" => "Find contact emails",
      "metadata" => { "priority" => "high" },
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets/ws_test/enrichments",
      {
        description: "Extract all email addresses",
        format: "text",
        options: [
          { label: "Personal" },
          { label: "Work" }
        ],
        metadata: { "priority" => "high" }
      }
    ]

    service = Exa::Services::Websets::CreateEnrichment.new(
      @connection,
      webset_id: "ws_test",
      description: "Extract all email addresses",
      format: "text",
      options: [
        { label: "Personal" },
        { label: "Work" }
      ],
      metadata: { "priority" => "high" }
    )
    result = service.call

    assert_instance_of Exa::Resources::WebsetEnrichment, result
    assert_equal "enrich_abc123", result.id
    assert_equal "webset_enrichment", result.object
    assert_equal "pending", result.status
    assert_equal "ws_test", result.webset_id
    assert_equal "Email Extraction", result.title
    assert_equal "Extract all email addresses", result.description
    assert_equal "text", result.format
    assert_equal 2, result.options.length
    assert_equal "Find contact emails", result.instructions
    assert_equal({ "priority" => "high" }, result.metadata)

    @connection.verify
  end

  def test_creates_enrichment_with_minimal_parameters
    response_body = {
      "id" => "enrich_min",
      "object" => "webset_enrichment",
      "status" => "pending",
      "websetId" => "ws_test",
      "description" => "Simple text extraction",
      "format" => "text",
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets/ws_test/enrichments",
      {
        description: "Simple text extraction",
        format: "text"
      }
    ]

    service = Exa::Services::Websets::CreateEnrichment.new(
      @connection,
      webset_id: "ws_test",
      description: "Simple text extraction",
      format: "text"
    )
    result = service.call

    assert_instance_of Exa::Resources::WebsetEnrichment, result
    assert_equal "enrich_min", result.id
    assert_equal "pending", result.status

    @connection.verify
  end
end
