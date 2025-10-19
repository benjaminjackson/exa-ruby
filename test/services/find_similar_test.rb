require "test_helper"
require_relative "../../lib/exa/services/find_similar"

class FindSimilarTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
  end

  def test_initialize_with_connection_and_params
    service = Exa::Services::FindSimilar.new(@connection, url: "https://example.com")

    assert_instance_of Exa::Services::FindSimilar, service
  end

  def test_call_posts_to_find_similar_endpoint
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .with(body: hash_including(url: "https://example.com"))
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::FindSimilar.new(@connection, url: "https://example.com")
    service.call

    assert_requested :post, "https://api.exa.ai/findSimilar"
  end

  def test_call_returns_find_similar_result_object
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .to_return(
        status: 200,
        body: {
          results: [
            { title: "Similar Page", url: "https://similar.com", score: 0.92 }
          ],
          requestId: "abc123",
          context: "similarity",
          costDollars: 0.001
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::FindSimilar.new(@connection, url: "https://example.com")
    result = service.call

    assert_instance_of Exa::Resources::FindSimilarResult, result
    assert_equal 1, result.results.length
    assert_equal "abc123", result.request_id
    assert_equal "similarity", result.context
    assert_equal 0.001, result.cost_dollars
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .to_return(
        status: 401,
        body: { error: "Invalid API key" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::FindSimilar.new(@connection, url: "https://example.com")

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end

  def test_call_raises_server_error_on_500
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .to_return(
        status: 500,
        body: { error: "Internal server error" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::FindSimilar.new(@connection, url: "https://example.com")

    assert_raises(Exa::InternalServerError) do
      service.call
    end
  end

  def test_call_sends_all_find_similar_parameters
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .with(
        body: hash_including(
          url: "https://example.com",
          numResults: 15,
          includeDomains: ["example.com"],
          excludeDomains: ["spam.com"]
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::FindSimilar.new(
      @connection,
      url: "https://example.com",
      numResults: 15,
      includeDomains: ["example.com"],
      excludeDomains: ["spam.com"]
    )
    service.call

    assert_requested :post, "https://api.exa.ai/findSimilar"
  end
end
