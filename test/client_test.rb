# frozen_string_literal: true

require "test_helper"

class ClientTest < Minitest::Test
  def setup
    # Reset WebMock request history before each test
    WebMock.reset!
  end

  def teardown
    # Reset module-level configuration after each test
    Exa.reset
  end

  def test_initialize_with_api_key
    client = Exa::Client.new(api_key: "test_key_123")

    assert_instance_of Exa::Client, client
  end

  def test_initialize_without_api_key_raises_configuration_error
    error = assert_raises(Exa::ConfigurationError) do
      Exa::Client.new
    end

    assert_match(/api key/i, error.message)
  end

  def test_initialize_uses_module_level_api_key_when_not_provided
    Exa.configure do |config|
      config.api_key = "module_level_key"
    end

    client = Exa::Client.new

    assert_instance_of Exa::Client, client
  end

  def test_initialize_with_custom_base_url_and_timeout
    client = Exa::Client.new(
      api_key: "test_key",
      base_url: "https://custom.api.url",
      timeout: 60
    )

    assert_instance_of Exa::Client, client
  end

  def test_search_returns_search_result
    stub_request(:post, "https://api.exa.ai/search")
      .with(body: hash_including(query: "ruby programming"))
      .to_return(
        status: 200,
        body: {
          results: [
            { title: "Ruby Tutorial", url: "https://example.com/ruby", score: 0.95 }
          ],
          requestId: "req_123"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.search("ruby programming")

    assert_instance_of Exa::Resources::SearchResult, result
    assert_equal 1, result.results.length
    assert_equal "req_123", result.request_id
  end

  def test_search_delegates_to_search_service
    stub_request(:post, "https://api.exa.ai/search")
      .with(body: hash_including(query: "test", type: "fast"))
      .to_return(
        status: 200,
        body: { results: [], requestId: "abc123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    client.search("test")

    assert_requested :post, "https://api.exa.ai/search", times: 1
  end

  def test_search_with_multiple_parameters
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "AI research",
          type: "deep",
          numResults: 20,
          category: "research paper"
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "xyz789" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.search(
      "AI research",
      type: "deep",
      numResults: 20,
      category: "research paper"
    )

    assert_instance_of Exa::Resources::SearchResult, result
    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_search_raises_error_when_unauthorized
    stub_request(:post, "https://api.exa.ai/search")
      .to_return(
        status: 401,
        body: { error: "Invalid API key" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "invalid_key")

    assert_raises(Exa::Unauthorized) do
      client.search("test query")
    end
  end

  def test_find_similar_delegates_to_service
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .with(body: hash_including(url: "https://example.com"))
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.find_similar("https://example.com")

    assert_instance_of Exa::Resources::FindSimilarResult, result
  end

  def test_find_similar_with_options
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .with(body: hash_including(url: "https://example.com", numResults: 20))
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.find_similar("https://example.com", numResults: 20)

    assert_instance_of Exa::Resources::FindSimilarResult, result
  end

  def test_get_contents_delegates_to_service
    stub_request(:post, "https://api.exa.ai/contents")
      .with(body: hash_including(urls: ["https://example.com"]))
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123", statuses: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.get_contents(["https://example.com"])

    assert_instance_of Exa::Resources::ContentsResult, result
  end

  def test_get_contents_with_text_options
    stub_request(:post, "https://api.exa.ai/contents")
      .with(body: hash_including(urls: ["https://example.com"], text: true))
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123", statuses: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.get_contents(["https://example.com"], text: true)

    assert_instance_of Exa::Resources::ContentsResult, result
  end

  def test_context_method_exists
    client = Exa::Client.new(api_key: "test_key")

    assert client.respond_to?(:context)
  end

  def test_context_returns_context_result
    stub_request(:post, "https://api.exa.ai/context")
      .with(body: hash_including(query: "React hooks"))
      .to_return(
        status: 200,
        body: {
          requestId: "req_context_123",
          query: "React hooks",
          response: "## State Management\n```javascript\nconst [state, setState] = useState(0);\n```",
          resultsCount: 502,
          costDollars: "{\"total\":1}",
          searchTime: 1.5,
          outputTokens: 1200
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.context("React hooks")

    assert_instance_of Exa::Resources::ContextResult, result
    assert_equal "req_context_123", result.request_id
    assert_equal "React hooks", result.query
  end

  def test_context_delegates_to_service
    stub_request(:post, "https://api.exa.ai/context")
      .with(body: hash_including(query: "Express middleware"))
      .to_return(
        status: 200,
        body: { requestId: "abc123", query: "Express middleware", response: "code", resultsCount: 10, costDollars: "0.001", searchTime: 1.0, outputTokens: 500 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    client.context("Express middleware")

    assert_requested :post, "https://api.exa.ai/context", times: 1
  end

  def test_context_with_tokens_num_parameter
    stub_request(:post, "https://api.exa.ai/context")
      .with(body: hash_including(query: "test", tokensNum: 5000))
      .to_return(
        status: 200,
        body: { requestId: "abc123", query: "test", response: "code", resultsCount: 10, costDollars: "0.001", searchTime: 1.0, outputTokens: 500 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.context("test", tokensNum: 5000)

    assert_instance_of Exa::Resources::ContextResult, result
  end

  def test_context_with_dynamic_tokens
    stub_request(:post, "https://api.exa.ai/context")
      .with(body: hash_including(query: "test", tokensNum: "dynamic"))
      .to_return(
        status: 200,
        body: { requestId: "abc123", query: "test", response: "code", resultsCount: 10, costDollars: "0.001", searchTime: 1.0, outputTokens: 500 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.context("test", tokensNum: "dynamic")

    assert_instance_of Exa::Resources::ContextResult, result
  end

  def test_linkedin_company_delegates_to_search
    stub_request(:post, "https://api.exa.ai/search")
      .with(body: hash_including(
        query: "Anthropic",
        type: "keyword",
        includeDomains: ["linkedin.com/company"]
      ))
      .to_return(
        status: 200,
        body: { results: [], requestId: "req_linkedin_123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.linkedin_company("Anthropic")

    assert_instance_of Exa::Resources::SearchResult, result
    assert_requested :post, "https://api.exa.ai/search", times: 1
  end

  def test_linkedin_company_with_num_results
    stub_request(:post, "https://api.exa.ai/search")
      .with(body: hash_including(
        query: "Google",
        type: "keyword",
        includeDomains: ["linkedin.com/company"],
        numResults: 5
      ))
      .to_return(
        status: 200,
        body: { results: [], requestId: "req_linkedin_456" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.linkedin_company("Google", numResults: 5)

    assert_instance_of Exa::Resources::SearchResult, result
  end

  def test_linkedin_person_delegates_to_search
    stub_request(:post, "https://api.exa.ai/search")
      .with(body: hash_including(
        query: "Dario Amodei",
        type: "keyword",
        includeDomains: ["linkedin.com/in"]
      ))
      .to_return(
        status: 200,
        body: { results: [], requestId: "req_linkedin_person_123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.linkedin_person("Dario Amodei")

    assert_instance_of Exa::Resources::SearchResult, result
    assert_requested :post, "https://api.exa.ai/search", times: 1
  end

  def test_linkedin_person_with_num_results
    stub_request(:post, "https://api.exa.ai/search")
      .with(body: hash_including(
        query: "Satya Nadella",
        type: "keyword",
        includeDomains: ["linkedin.com/in"],
        numResults: 3
      ))
      .to_return(
        status: 200,
        body: { results: [], requestId: "req_linkedin_person_456" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.linkedin_person("Satya Nadella", numResults: 3)

    assert_instance_of Exa::Resources::SearchResult, result
  end

  def test_answer_stream_delegates_to_service
    sse_response = "data: {\"choices\":[{\"delta\":{\"role\":\"assistant\",\"content\":\"Hello\"}}]}\n\n"

    stub_request(:post, "https://api.exa.ai/answer")
      .with(body: hash_including(query: "test", stream: true))
      .to_return(
        status: 200,
        body: sse_response,
        headers: { "Content-Type" => "text/event-stream" }
      )

    client = Exa::Client.new(api_key: "test_key")
    chunks = []
    client.answer_stream("test") { |chunk| chunks << chunk }

    assert_equal 1, chunks.length
    assert_equal "Hello", chunks[0]["choices"][0]["delta"]["content"]
  end

  def test_list_websets_returns_webset_collection
    stub_request(:get, "https://api.exa.ai/websets/v0/websets")
      .to_return(
        status: 200,
        body: {
          data: [
            { id: "ws_123", status: "idle" }
          ],
          hasMore: false,
          nextCursor: nil
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.list_websets

    assert_instance_of Exa::Resources::WebsetCollection, result
    assert_equal 1, result.data.length
  end

  def test_list_websets_delegates_to_list_service
    stub_request(:get, "https://api.exa.ai/websets/v0/websets")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    client.list_websets

    assert_requested :get, "https://api.exa.ai/websets/v0/websets", times: 1
  end

  def test_list_websets_with_pagination_parameters
    stub_request(:get, "https://api.exa.ai/websets/v0/websets")
      .with(query: hash_including("cursor" => "next_page", "limit" => "10"))
      .to_return(
        status: 200,
        body: {
          data: [],
          hasMore: true,
          nextCursor: "cursor_abc"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.list_websets(cursor: "next_page", limit: 10)

    assert_instance_of Exa::Resources::WebsetCollection, result
    assert_equal true, result.has_more
  end

  def test_get_webset_returns_webset
    stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123")
      .to_return(
        status: 200,
        body: {
          id: "ws_123",
          object: "webset",
          status: "idle",
          searches: [],
          imports: [],
          enrichments: [],
          monitors: [],
          excludes: [],
          items: []
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.get_webset("ws_123")

    assert_instance_of Exa::Resources::Webset, result
    assert_equal "ws_123", result.id
  end

  def test_delete_webset_returns_deleted_webset
    stub_request(:delete, "https://api.exa.ai/websets/v0/websets/ws_123")
      .to_return(
        status: 200,
        body: {
          id: "ws_123",
          object: "webset",
          status: "deleted",
          searches: [],
          imports: [],
          enrichments: [],
          monitors: [],
          excludes: [],
          items: []
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.delete_webset("ws_123")

    assert_instance_of Exa::Resources::Webset, result
    assert_equal "ws_123", result.id
  end

  def test_cancel_webset_returns_webset
    stub_request(:post, "https://api.exa.ai/websets/v0/websets/ws_123/cancel")
      .to_return(
        status: 200,
        body: {
          id: "ws_123",
          object: "webset",
          status: "cancelled",
          searches: [],
          imports: [],
          enrichments: [],
          monitors: [],
          excludes: [],
          items: []
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.cancel_webset("ws_123")

    assert_instance_of Exa::Resources::Webset, result
  end

  def test_update_webset_returns_updated_webset
    stub_request(:post, "https://api.exa.ai/websets/v0/websets/ws_123")
      .with(body: hash_including(metadata: { "tag" => "updated" }))
      .to_return(
        status: 200,
        body: {
          id: "ws_123",
          object: "webset",
          status: "idle",
          metadata: { "tag" => "updated" },
          searches: [],
          imports: [],
          enrichments: [],
          monitors: [],
          excludes: [],
          items: []
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.update_webset("ws_123", metadata: { "tag" => "updated" })

    assert_instance_of Exa::Resources::Webset, result
  end

  def test_create_webset_returns_new_webset
    stub_request(:post, "https://api.exa.ai/websets/v0/websets")
      .with(body: hash_including(search: { query: "test", count: 1 }))
      .to_return(
        status: 200,
        body: {
          id: "ws_new",
          object: "webset",
          status: "processing",
          searches: [{ id: "search_1", query: "test" }],
          imports: [],
          enrichments: [],
          monitors: [],
          excludes: [],
          items: []
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.create_webset(search: { query: "test", count: 1 })

    assert_instance_of Exa::Resources::Webset, result
    assert_equal "ws_new", result.id
  end

  def test_create_enrichment_returns_enrichment
    stub_request(:post, "https://api.exa.ai/websets/v0/websets/ws_123/enrichments")
      .with(body: hash_including(description: "Extract emails", format: "text"))
      .to_return(
        status: 200,
        body: {
          id: "enrich_abc",
          object: "webset_enrichment",
          status: "pending",
          websetId: "ws_123",
          description: "Extract emails",
          format: "text"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.create_enrichment(
      webset_id: "ws_123",
      description: "Extract emails",
      format: "text"
    )

    assert_instance_of Exa::Resources::WebsetEnrichment, result
    assert_equal "enrich_abc", result.id
  end

  def test_get_enrichment_returns_enrichment
    stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123/enrichments/enrich_abc")
      .to_return(
        status: 200,
        body: {
          id: "enrich_abc",
          object: "webset_enrichment",
          status: "completed",
          websetId: "ws_123",
          description: "Extract emails",
          format: "text"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.get_enrichment(webset_id: "ws_123", id: "enrich_abc")

    assert_instance_of Exa::Resources::WebsetEnrichment, result
    assert_equal "enrich_abc", result.id
    assert_equal "completed", result.status
  end

  def test_update_enrichment_returns_updated_enrichment
    stub_request(:patch, "https://api.exa.ai/websets/v0/websets/ws_123/enrichments/enrich_abc")
      .with(body: hash_including(description: "Updated description"))
      .to_return(
        status: 200,
        body: {
          id: "enrich_abc",
          object: "webset_enrichment",
          status: "pending",
          websetId: "ws_123",
          description: "Updated description",
          format: "text"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.update_enrichment(
      webset_id: "ws_123",
      id: "enrich_abc",
      description: "Updated description"
    )

    assert_instance_of Exa::Resources::WebsetEnrichment, result
    assert_equal "Updated description", result.description
  end

  def test_delete_enrichment_returns_deleted_enrichment
    stub_request(:delete, "https://api.exa.ai/websets/v0/websets/ws_123/enrichments/enrich_abc")
      .to_return(
        status: 200,
        body: {
          id: "enrich_abc",
          object: "webset_enrichment",
          status: "deleted",
          websetId: "ws_123",
          description: "Extract emails",
          format: "text"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.delete_enrichment(webset_id: "ws_123", id: "enrich_abc")

    assert_instance_of Exa::Resources::WebsetEnrichment, result
    assert_equal "deleted", result.status
  end

  def test_cancel_enrichment_returns_cancelled_enrichment
    stub_request(:post, "https://api.exa.ai/websets/v0/websets/ws_123/enrichments/enrich_abc/cancel")
      .to_return(
        status: 200,
        body: {
          id: "enrich_abc",
          object: "webset_enrichment",
          status: "cancelled",
          websetId: "ws_123",
          description: "Extract emails",
          format: "text"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.cancel_enrichment(webset_id: "ws_123", id: "enrich_abc")

    assert_instance_of Exa::Resources::WebsetEnrichment, result
    assert_equal "cancelled", result.status
  end

  def test_list_imports_returns_import_collection
    stub_request(:get, "https://api.exa.ai/websets/v0/imports")
      .to_return(
        status: 200,
        body: {
          data: [
            { id: "imp_123", status: "pending", format: "csv" }
          ],
          hasMore: false,
          nextCursor: nil
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.list_imports

    assert_instance_of Exa::Resources::ImportCollection, result
    assert_equal 1, result.data.length
  end

  def test_list_imports_delegates_to_list_service
    stub_request(:get, "https://api.exa.ai/websets/v0/imports")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    client.list_imports

    assert_requested :get, "https://api.exa.ai/websets/v0/imports", times: 1
  end

  def test_create_import_returns_import
    stub_request(:post, "https://api.exa.ai/websets/v0/imports")
      .with(body: hash_including(title: "Test Import", format: "csv", size: 100, count: 50))
      .to_return(
        status: 200,
        body: {
          id: "imp_new",
          object: "import",
          status: "pending",
          title: "Test Import",
          format: "csv",
          size: 100,
          count: 50,
          entity: { type: "company" },
          uploadUrl: "https://upload.example.com",
          uploadValidUntil: "2025-11-24T00:00:00Z"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.create_import(
      title: "Test Import",
      format: "csv",
      size: 100,
      count: 50,
      entity: { type: "company" }
    )

    assert_instance_of Exa::Resources::Import, result
    assert_equal "imp_new", result.id
    assert_equal "pending", result.status
  end

  def test_get_import_returns_import
    stub_request(:get, "https://api.exa.ai/websets/v0/imports/imp_123")
      .to_return(
        status: 200,
        body: {
          id: "imp_123",
          object: "import",
          status: "completed",
          title: "My Import",
          format: "csv",
          count: 100,
          entity: { type: "company" }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.get_import("imp_123")

    assert_instance_of Exa::Resources::Import, result
    assert_equal "imp_123", result.id
    assert_equal "completed", result.status
  end

  def test_update_import_returns_updated_import
    stub_request(:patch, "https://api.exa.ai/websets/v0/imports/imp_123")
      .with(body: hash_including(title: "Updated Title"))
      .to_return(
        status: 200,
        body: {
          id: "imp_123",
          object: "import",
          status: "pending",
          title: "Updated Title",
          format: "csv",
          count: 100,
          entity: { type: "company" }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.update_import("imp_123", title: "Updated Title")

    assert_instance_of Exa::Resources::Import, result
    assert_equal "Updated Title", result.title
  end

  def test_delete_import_returns_deleted_import
    stub_request(:delete, "https://api.exa.ai/websets/v0/imports/imp_123")
      .to_return(
        status: 200,
        body: {
          id: "imp_123",
          object: "import",
          status: "deleted",
          title: "Deleted Import",
          format: "csv",
          count: 100,
          entity: { type: "company" }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.delete_import("imp_123")

    assert_instance_of Exa::Resources::Import, result
    assert_equal "imp_123", result.id
  end
end
