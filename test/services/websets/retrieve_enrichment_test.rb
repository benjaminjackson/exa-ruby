# frozen_string_literal: true

require "test_helper"

class WebsetsRetrieveEnrichmentTest < Minitest::Test
  def setup
    @connection = Minitest::Mock.new
  end

  def test_retrieves_enrichment_by_id
    response_body = {
      "id" => "enrich_abc123",
      "object" => "webset_enrichment",
      "status" => "completed",
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
      "updatedAt" => "2024-01-15T11:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :get, response, ["/websets/v0/websets/ws_test/enrichments/enrich_abc123"]

    service = Exa::Services::Websets::RetrieveEnrichment.new(
      @connection,
      webset_id: "ws_test",
      id: "enrich_abc123"
    )
    result = service.call

    assert_instance_of Exa::Resources::WebsetEnrichment, result
    assert_equal "enrich_abc123", result.id
    assert_equal "webset_enrichment", result.object
    assert_equal "completed", result.status
    assert_equal "ws_test", result.webset_id
    assert_equal "Email Extraction", result.title
    assert_equal "Extract all email addresses", result.description
    assert_equal "text", result.format

    @connection.verify
  end
end
