# frozen_string_literal: true

require "test_helper"

class WebsetsDeleteEnrichmentTest < Minitest::Test
  def setup
    @connection = Minitest::Mock.new
  end

  def test_deletes_enrichment
    response_body = {
      "id" => "enrich_abc123",
      "object" => "webset_enrichment",
      "status" => "deleted",
      "websetId" => "ws_test",
      "description" => "Extract emails",
      "format" => "text",
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T12:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :delete, response, ["/websets/v0/websets/ws_test/enrichments/enrich_abc123"]

    service = Exa::Services::Websets::DeleteEnrichment.new(
      @connection,
      webset_id: "ws_test",
      id: "enrich_abc123"
    )
    result = service.call

    assert_instance_of Exa::Resources::WebsetEnrichment, result
    assert_equal "enrich_abc123", result.id
    assert_equal "deleted", result.status

    @connection.verify
  end
end
