# frozen_string_literal: true

require "test_helper"

class ClientTest < Minitest::Test
  def setup
    super
    # Reset WebMock request history before each test
    WebMock.reset!
  end

  def teardown
    # Reset module-level configuration after each test
    Exa.reset
    super
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
      .with(body: hash_including(query: "test", type: "auto"))
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

  def stub_search_monitor_call(method, path, body)
    stub_request(method, "https://api.exa.ai#{path}")
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def test_search_monitor_create_returns_search_monitor
    stub_search_monitor_call(:post, "/monitors", { id: "mon_123", status: "active", webhookSecret: "whsec_1" })

    client = Exa::Client.new(api_key: "test_key")
    result = client.search_monitor_create(
      search: { query: "AI/ML infrastructure startups with Series A funding" },
      webhook: { url: "https://example.com/webhooks/exa" }
    )

    assert_instance_of Exa::Resources::SearchMonitor, result
    assert_equal "whsec_1", result.webhook_secret
  end

  def test_search_monitor_list_returns_search_monitor_list
    stub_search_monitor_call(:get, "/monitors?status=paused", { data: [{ id: "mon_123" }], hasMore: false })

    client = Exa::Client.new(api_key: "test_key")
    result = client.search_monitor_list(status: "paused")

    assert_instance_of Exa::Resources::SearchMonitorList, result
    assert_equal "mon_123", result.data.first.id
  end

  def test_search_monitor_get_returns_search_monitor
    stub_search_monitor_call(:get, "/monitors/mon_123", { id: "mon_123", status: "active" })

    client = Exa::Client.new(api_key: "test_key")
    result = client.search_monitor_get("mon_123")

    assert_equal "mon_123", result.id
  end

  def test_search_monitor_update_patches_search_monitor
    stub_search_monitor_call(:patch, "/monitors/mon_123", { id: "mon_123", status: "paused" })

    client = Exa::Client.new(api_key: "test_key")
    result = client.search_monitor_update("mon_123", status: "paused")

    assert_requested :patch, "https://api.exa.ai/monitors/mon_123", body: { status: "paused" }.to_json
    assert result.paused?
  end

  def test_agent_run_stop_returns_completed_run_with_stopped_reason
    stub_request(:post, "https://api.exa.ai/agent/runs/run_123/stop")
      .to_return(
        status: 200,
        body: { id: "run_123", object: "agent_run", status: "completed", stopReason: "stopped" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.agent_run_stop("run_123")

    assert_requested :post, "https://api.exa.ai/agent/runs/run_123/stop"
    assert_equal "stopped", result.stop_reason
  end

  def test_search_monitor_delete_returns_deleted_monitor
    stub_search_monitor_call(:delete, "/monitors/mon_123", { id: "mon_123", status: "active" })

    client = Exa::Client.new(api_key: "test_key")
    result = client.search_monitor_delete("mon_123")

    assert_requested :delete, "https://api.exa.ai/monitors/mon_123"
    assert_equal "mon_123", result.id
  end

  def test_search_monitor_trigger_returns_trigger_result
    stub_search_monitor_call(:post, "/monitors/mon_123/trigger", { triggered: true })

    client = Exa::Client.new(api_key: "test_key")
    result = client.search_monitor_trigger("mon_123")

    assert_equal true, result.triggered
  end

  def test_search_monitor_batch_defaults_to_dry_run
    stub_search_monitor_call(:post, "/monitors/batch", { action: "pause", affected: 0, ids: [], dry_run: true, has_more: false })

    client = Exa::Client.new(api_key: "test_key")
    result = client.search_monitor_batch(action: "pause", filter: { status: "active" })

    assert_requested :post, "https://api.exa.ai/monitors/batch",
      body: { action: "pause", filter: { status: "active" }, dry_run: true }.to_json
    assert_instance_of Exa::Resources::SearchMonitorBatchResult, result
  end

  def test_search_monitor_runs_list_returns_run_list
    stub_search_monitor_call(:get, "/monitors/mon_123/runs", { data: [{ id: "run_1", monitorId: "mon_123" }], hasMore: false })

    client = Exa::Client.new(api_key: "test_key")
    result = client.search_monitor_runs_list("mon_123")

    assert_instance_of Exa::Resources::SearchMonitorList, result
    assert_equal "run_1", result.data.first.id
  end

  def test_search_monitor_runs_get_returns_run
    stub_search_monitor_call(:get, "/monitors/mon_123/runs/run_1", { id: "run_1", monitorId: "mon_123", status: "running" })

    client = Exa::Client.new(api_key: "test_key")
    result = client.search_monitor_runs_get("mon_123", "run_1")

    assert_instance_of Exa::Resources::SearchMonitorRun, result
    assert result.running?
  end
end
