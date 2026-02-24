# frozen_string_literal: true

require "test_helper"

class WebsetsUpdateTest < Minitest::Test
  def setup
    @connection = Minitest::Mock.new
  end

  def test_updates_webset_metadata
    response_body = {
      "id" => "ws_abc123",
      "object" => "webset",
      "status" => "idle",
      "externalId" => nil,
      "title" => nil,
      "searches" => [],
      "imports" => [],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [],
      "metadata" => { "project" => "Q1-2025" },
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T11:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets/ws_abc123",
      { metadata: { "project" => "Q1-2025" } }
    ]

    service = Exa::Services::Websets::Update.new(@connection,
      id: "ws_abc123",
      metadata: { "project" => "Q1-2025" }
    )
    result = service.call

    assert_instance_of Exa::Resources::Webset, result
    assert_equal "ws_abc123", result.id
    assert_equal({ "project" => "Q1-2025" }, result.metadata)
    @connection.verify
  end

  def test_updates_webset_title
    response_body = {
      "id" => "ws_abc123",
      "object" => "webset",
      "status" => "idle",
      "externalId" => nil,
      "title" => "My Research Project",
      "searches" => [],
      "imports" => [],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [],
      "metadata" => {},
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T11:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets/ws_abc123",
      { title: "My Research Project" }
    ]

    service = Exa::Services::Websets::Update.new(@connection,
      id: "ws_abc123",
      title: "My Research Project"
    )
    result = service.call

    assert_instance_of Exa::Resources::Webset, result
    assert_equal "My Research Project", result.title
    @connection.verify
  end

  def test_updates_webset_title_and_metadata
    response_body = {
      "id" => "ws_abc123",
      "object" => "webset",
      "status" => "idle",
      "externalId" => nil,
      "title" => "Q1 Research",
      "searches" => [],
      "imports" => [],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [],
      "metadata" => { "project" => "growth" },
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T11:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets/ws_abc123",
      { title: "Q1 Research", metadata: { "project" => "growth" } }
    ]

    service = Exa::Services::Websets::Update.new(@connection,
      id: "ws_abc123",
      title: "Q1 Research",
      metadata: { "project" => "growth" }
    )
    result = service.call

    assert_equal "Q1 Research", result.title
    assert_equal({ "project" => "growth" }, result.metadata)
    @connection.verify
  end
end
