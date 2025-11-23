# frozen_string_literal: true

require "test_helper"

class WebsetsCreateTest < Minitest::Test
  def setup
    @connection = Minitest::Mock.new
  end

  def test_creates_webset_with_basic_search
    response_body = {
      "id" => "ws_abc123",
      "object" => "webset",
      "status" => "pending",
      "externalId" => nil,
      "title" => nil,
      "searches" => [{
        "id" => "search_xyz",
        "query" => "AI startups in San Francisco",
        "status" => "created"
      }],
      "imports" => [],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [],
      "metadata" => {},
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets",
      {
        search: {
          query: "AI startups in San Francisco",
          count: 10
        }
      }
    ]

    service = Exa::Services::Websets::Create.new(@connection, search: {
      query: "AI startups in San Francisco",
      count: 10
    })
    result = service.call

    assert_instance_of Exa::Resources::Webset, result
    assert_equal "ws_abc123", result.id
    assert_equal "webset", result.object
    assert_equal "pending", result.status
    assert_nil result.external_id
    assert_equal 1, result.searches.length
    assert_equal [], result.imports

    @connection.verify
  end

  def test_creates_webset_with_external_id
    response_body = {
      "id" => "ws_def456",
      "object" => "webset",
      "status" => "idle",
      "externalId" => "my-custom-id-123",
      "title" => nil,
      "searches" => [],
      "imports" => [],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [],
      "metadata" => {},
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets",
      {
        search: { query: "test", count: 5 },
        externalId: "my-custom-id-123"
      }
    ]

    service = Exa::Services::Websets::Create.new(@connection,
      search: { query: "test", count: 5 },
      externalId: "my-custom-id-123"
    )
    result = service.call

    assert_equal "my-custom-id-123", result.external_id
    @connection.verify
  end

  def test_creates_webset_with_metadata
    response_body = {
      "id" => "ws_meta",
      "object" => "webset",
      "status" => "idle",
      "externalId" => nil,
      "title" => nil,
      "searches" => [],
      "imports" => [],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [],
      "metadata" => { "project" => "Q1-2024", "owner" => "research-team" },
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets",
      {
        search: { query: "test", count: 1 },
        metadata: { "project" => "Q1-2024", "owner" => "research-team" }
      }
    ]

    service = Exa::Services::Websets::Create.new(@connection,
      search: { query: "test", count: 1 },
      metadata: { "project" => "Q1-2024", "owner" => "research-team" }
    )
    result = service.call

    assert_equal({ "project" => "Q1-2024", "owner" => "research-team" }, result.metadata)
    @connection.verify
  end

  def test_creates_webset_with_search_criteria
    response_body = {
      "id" => "ws_criteria",
      "object" => "webset",
      "status" => "running",
      "externalId" => nil,
      "title" => nil,
      "searches" => [{
        "id" => "search_123",
        "query" => "Marketing agencies in the US",
        "criteria" => [
          { "description" => "focused on consumer products" },
          { "description" => "50+ employees" }
        ],
        "status" => "running"
      }],
      "imports" => [],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [],
      "metadata" => {},
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets",
      {
        search: {
          query: "Marketing agencies in the US",
          count: 20,
          criteria: [
            { description: "focused on consumer products" },
            { description: "50+ employees" }
          ]
        }
      }
    ]

    service = Exa::Services::Websets::Create.new(@connection,
      search: {
        query: "Marketing agencies in the US",
        count: 20,
        criteria: [
          { description: "focused on consumer products" },
          { description: "50+ employees" }
        ]
      }
    )
    result = service.call

    assert_equal "ws_criteria", result.id
    assert_equal "running", result.status
    @connection.verify
  end

  def test_creates_webset_with_entity_type
    response_body = {
      "id" => "ws_entity",
      "object" => "webset",
      "status" => "pending",
      "externalId" => nil,
      "title" => nil,
      "searches" => [{
        "id" => "search_456",
        "query" => "tech founders",
        "entity" => { "type" => "person" },
        "status" => "created"
      }],
      "imports" => [],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [],
      "metadata" => {},
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets",
      {
        search: {
          query: "tech founders",
          count: 15,
          entity: { type: "person" }
        }
      }
    ]

    service = Exa::Services::Websets::Create.new(@connection,
      search: {
        query: "tech founders",
        count: 15,
        entity: { type: "person" }
      }
    )
    result = service.call

    assert_equal "ws_entity", result.id
    @connection.verify
  end

  def test_creates_webset_with_enrichments
    response_body = {
      "id" => "ws_enrich",
      "object" => "webset",
      "status" => "pending",
      "externalId" => nil,
      "title" => nil,
      "searches" => [],
      "imports" => [],
      "enrichments" => [{
        "id" => "enrich_001",
        "description" => "Extract email addresses",
        "format" => "text",
        "status" => "pending"
      }],
      "monitors" => [],
      "excludes" => [],
      "metadata" => {},
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets",
      {
        search: { query: "companies", count: 10 },
        enrichments: [{
          description: "Extract email addresses",
          format: "text"
        }]
      }
    ]

    service = Exa::Services::Websets::Create.new(@connection,
      search: { query: "companies", count: 10 },
      enrichments: [{
        description: "Extract email addresses",
        format: "text"
      }]
    )
    result = service.call

    assert_equal 1, result.enrichments.length
    @connection.verify
  end

  def test_creates_webset_with_import_sources
    response_body = {
      "id" => "ws_import",
      "object" => "webset",
      "status" => "processing",
      "externalId" => nil,
      "title" => nil,
      "searches" => [],
      "imports" => [{
        "id" => "import_123",
        "source" => "import",
        "status" => "processing"
      }],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [],
      "metadata" => {},
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets",
      {
        import: [{
          source: "import",
          id: "import_abc123"
        }]
      }
    ]

    service = Exa::Services::Websets::Create.new(@connection,
      import: [{
        source: "import",
        id: "import_abc123"
      }]
    )
    result = service.call

    assert_equal 1, result.imports.length
    @connection.verify
  end

  def test_creates_webset_with_exclude_sources
    response_body = {
      "id" => "ws_exclude",
      "object" => "webset",
      "status" => "pending",
      "externalId" => nil,
      "title" => nil,
      "searches" => [],
      "imports" => [],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [{
        "source" => "webset",
        "id" => "ws_old123"
      }],
      "metadata" => {},
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets",
      {
        search: { query: "new companies", count: 10 },
        exclude: [{
          source: "webset",
          id: "ws_old123"
        }]
      }
    ]

    service = Exa::Services::Websets::Create.new(@connection,
      search: { query: "new companies", count: 10 },
      exclude: [{
        source: "webset",
        id: "ws_old123"
      }]
    )
    result = service.call

    assert_equal 1, result.excludes.length
    @connection.verify
  end

  def test_creates_webset_with_search_scope
    response_body = {
      "id" => "ws_scope",
      "object" => "webset",
      "status" => "running",
      "externalId" => nil,
      "title" => nil,
      "searches" => [{
        "id" => "search_scoped",
        "query" => "people who changed jobs",
        "scope" => [{
          "source" => "import",
          "id" => "import_csv123"
        }],
        "status" => "running"
      }],
      "imports" => [],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [],
      "metadata" => {},
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets",
      {
        search: {
          query: "people who changed jobs",
          count: 10,
          scope: [{
            source: "import",
            id: "import_csv123"
          }]
        }
      }
    ]

    service = Exa::Services::Websets::Create.new(@connection,
      search: {
        query: "people who changed jobs",
        count: 10,
        scope: [{
          source: "import",
          id: "import_csv123"
        }]
      }
    )
    result = service.call

    assert_equal "ws_scope", result.id
    @connection.verify
  end

  def test_creates_webset_with_hop_search_relationship
    response_body = {
      "id" => "ws_hop",
      "object" => "webset",
      "status" => "running",
      "externalId" => nil,
      "title" => nil,
      "searches" => [{
        "id" => "search_hop",
        "query" => "investors",
        "scope" => [{
          "source" => "webset",
          "id" => "ws_companies",
          "relationship" => {
            "definition" => "investors of",
            "limit" => 3
          }
        }],
        "status" => "running"
      }],
      "imports" => [],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [],
      "metadata" => {},
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets",
      {
        search: {
          query: "investors",
          count: 50,
          scope: [{
            source: "webset",
            id: "ws_companies",
            relationship: {
              definition: "investors of",
              limit: 3
            }
          }]
        }
      }
    ]

    service = Exa::Services::Websets::Create.new(@connection,
      search: {
        query: "investors",
        count: 50,
        scope: [{
          source: "webset",
          id: "ws_companies",
          relationship: {
            definition: "investors of",
            limit: 3
          }
        }]
      }
    )
    result = service.call

    assert_equal "ws_hop", result.id
    @connection.verify
  end

  def test_creates_webset_with_recall_enabled
    response_body = {
      "id" => "ws_recall",
      "object" => "webset",
      "status" => "running",
      "externalId" => nil,
      "title" => nil,
      "searches" => [{
        "id" => "search_recall",
        "query" => "biotech companies",
        "recall" => true,
        "status" => "running"
      }],
      "imports" => [],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [],
      "metadata" => {},
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets",
      {
        search: {
          query: "biotech companies",
          count: 100,
          recall: true
        }
      }
    ]

    service = Exa::Services::Websets::Create.new(@connection,
      search: {
        query: "biotech companies",
        count: 100,
        recall: true
      }
    )
    result = service.call

    assert_equal "ws_recall", result.id
    @connection.verify
  end

  def test_creates_webset_with_custom_entity
    response_body = {
      "id" => "ws_custom",
      "object" => "webset",
      "status" => "pending",
      "externalId" => nil,
      "title" => nil,
      "searches" => [{
        "id" => "search_custom",
        "query" => "research grants",
        "entity" => {
          "type" => "custom",
          "description" => "research grant opportunities"
        },
        "status" => "created"
      }],
      "imports" => [],
      "enrichments" => [],
      "monitors" => [],
      "excludes" => [],
      "metadata" => {},
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets",
      {
        search: {
          query: "research grants",
          count: 25,
          entity: {
            type: "custom",
            description: "research grant opportunities"
          }
        }
      }
    ]

    service = Exa::Services::Websets::Create.new(@connection,
      search: {
        query: "research grants",
        count: 25,
        entity: {
          type: "custom",
          description: "research grant opportunities"
        }
      }
    )
    result = service.call

    assert_equal "ws_custom", result.id
    @connection.verify
  end

  def test_creates_webset_with_enrichment_options
    response_body = {
      "id" => "ws_options",
      "object" => "webset",
      "status" => "pending",
      "externalId" => nil,
      "title" => nil,
      "searches" => [],
      "imports" => [],
      "enrichments" => [{
        "id" => "enrich_options",
        "description" => "Categorize company size",
        "format" => "options",
        "options" => [
          { "label" => "Small (1-50)" },
          { "label" => "Medium (51-250)" },
          { "label" => "Large (251+)" }
        ],
        "status" => "pending"
      }],
      "monitors" => [],
      "excludes" => [],
      "metadata" => {},
      "createdAt" => "2024-01-15T10:00:00Z",
      "updatedAt" => "2024-01-15T10:00:00Z"
    }

    response = Minitest::Mock.new
    response.expect :body, response_body

    @connection.expect :post, response, [
      "/websets/v0/websets",
      {
        search: { query: "companies", count: 10 },
        enrichments: [{
          description: "Categorize company size",
          format: "options",
          options: [
            { label: "Small (1-50)" },
            { label: "Medium (51-250)" },
            { label: "Large (251+)" }
          ]
        }]
      }
    ]

    service = Exa::Services::Websets::Create.new(@connection,
      search: { query: "companies", count: 10 },
      enrichments: [{
        description: "Categorize company size",
        format: "options",
        options: [
          { label: "Small (1-50)" },
          { label: "Medium (51-250)" },
          { label: "Large (251+)" }
        ]
      }]
    )
    result = service.call

    assert_equal 1, result.enrichments.length
    @connection.verify
  end
end
