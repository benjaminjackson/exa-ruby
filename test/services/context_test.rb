require "test_helper"

class ContextTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
  end

  def test_initialize_with_connection_and_params
    service = Exa::Services::Context.new(@connection, query: "test query")

    assert_instance_of Exa::Services::Context, service
  end

  def test_call_posts_to_context_endpoint
    stub_request(:post, "https://api.exa.ai/context")
      .with(body: hash_including(query: "test query"))
      .to_return(
        status: 200,
        body: {
          requestId: "abc123",
          query: "test query",
          response: "code here",
          resultsCount: 15,
          costDollars: "0.005",
          searchTime: 1.5,
          outputTokens: 1200
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Context.new(@connection, query: "test query")
    service.call

    assert_requested :post, "https://api.exa.ai/context"
  end

  def test_call_returns_context_result_object
    stub_request(:post, "https://api.exa.ai/context")
      .to_return(
        status: 200,
        body: {
          requestId: "abc123",
          query: "React hooks",
          response: "## State Management\n```javascript\nconst [state, setState] = useState(0);\n```",
          resultsCount: 502,
          costDollars: "{\"total\":1,\"search\":{\"neural\":1}}",
          searchTime: 3112.29,
          outputTokens: 4805
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Context.new(@connection, query: "React hooks")
    result = service.call

    assert_instance_of Exa::Resources::ContextResult, result
    assert_equal "abc123", result.request_id
    assert_equal "React hooks", result.query
    assert_equal 502, result.results_count
    assert_equal 4805, result.output_tokens
  end

  def test_call_sends_query_parameter
    stub_request(:post, "https://api.exa.ai/context")
      .with(body: hash_including(query: "React hooks"))
      .to_return(
        status: 200,
        body: { requestId: "abc123", query: "React hooks", response: "code", resultsCount: 15, costDollars: "0.005", searchTime: 1.5, outputTokens: 1200 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Context.new(@connection, query: "React hooks")
    service.call

    assert_requested :post, "https://api.exa.ai/context"
  end

  def test_call_sends_tokens_num_parameter
    stub_request(:post, "https://api.exa.ai/context")
      .with(body: hash_including(query: "test", tokensNum: 5000))
      .to_return(
        status: 200,
        body: { requestId: "abc123", query: "test", response: "code", resultsCount: 15, costDollars: "0.005", searchTime: 1.5, outputTokens: 1200 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Context.new(@connection, query: "test", tokensNum: 5000)
    service.call

    assert_requested :post, "https://api.exa.ai/context"
  end

  def test_call_sends_dynamic_tokens_num
    stub_request(:post, "https://api.exa.ai/context")
      .with(body: hash_including(query: "test", tokensNum: "dynamic"))
      .to_return(
        status: 200,
        body: { requestId: "abc123", query: "test", response: "code", resultsCount: 15, costDollars: "0.005", searchTime: 1.5, outputTokens: 1200 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Context.new(@connection, query: "test", tokensNum: "dynamic")
    service.call

    assert_requested :post, "https://api.exa.ai/context"
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:post, "https://api.exa.ai/context")
      .to_return(
        status: 401,
        body: { error: "Invalid API key" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Context.new(@connection, query: "test")

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end

  def test_call_raises_bad_request_on_400
    stub_request(:post, "https://api.exa.ai/context")
      .to_return(
        status: 400,
        body: { error: "Bad request" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Context.new(@connection, query: "test")

    assert_raises(Exa::BadRequest) do
      service.call
    end
  end

  def test_call_raises_server_error_on_500
    stub_request(:post, "https://api.exa.ai/context")
      .to_return(
        status: 500,
        body: { error: "Internal server error" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Context.new(@connection, query: "test")

    assert_raises(Exa::InternalServerError) do
      service.call
    end
  end
end
