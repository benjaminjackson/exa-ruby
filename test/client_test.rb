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
      .with(body: { query: "test" })
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
          type: "neural",
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
      type: "neural",
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
end
