require "test_helper"
require_relative "../../lib/exa/services/get_contents"
require_relative "../../lib/exa/resources/contents_result"

class GetContentsTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
  end

  def test_initialize_with_connection_and_params
    service = Exa::Services::GetContents.new(@connection, urls: ["https://example.com"])

    assert_instance_of Exa::Services::GetContents, service
  end

  def test_call_posts_to_contents_endpoint
    stub_request(:post, "https://api.exa.ai/contents")
      .with(body: hash_including(urls: ["https://example.com"]))
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::GetContents.new(@connection, urls: ["https://example.com"])
    service.call

    assert_requested :post, "https://api.exa.ai/contents"
  end

  def test_call_returns_contents_result_object
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(
        status: 200,
        body: {
          results: [
            { url: "https://example.com", title: "Example", text: "Sample content" }
          ],
          requestId: "abc123",
          context: "formatted context",
          statuses: [{ id: "https://example.com", status: "success" }],
          costDollars: 0.001
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::GetContents.new(@connection, urls: ["https://example.com"])
    result = service.call

    assert_instance_of Exa::Resources::ContentsResult, result
    assert_equal 1, result.results.length
    assert_equal "abc123", result.request_id
    assert_equal "formatted context", result.context
    assert_equal 1, result.statuses.length
    assert_equal 0.001, result.cost_dollars
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(
        status: 401,
        body: { error: "Invalid API key" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::GetContents.new(@connection, urls: ["https://example.com"])

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end

  def test_call_raises_server_error_on_500
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(
        status: 500,
        body: { error: "Internal server error" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::GetContents.new(@connection, urls: ["https://example.com"])

    assert_raises(Exa::InternalServerError) do
      service.call
    end
  end

  def test_call_sends_all_contents_parameters
    stub_request(:post, "https://api.exa.ai/contents")
      .with(
        body: hash_including(
          urls: ["https://example.com", "https://example.org"],
          text: true,
          highlights: { numSentences: 3 },
          summary: { query: "main points" },
          subpages: 2,
          livecrawl: "always"
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::GetContents.new(
      @connection,
      urls: ["https://example.com", "https://example.org"],
      text: true,
      highlights: { numSentences: 3 },
      summary: { query: "main points" },
      subpages: 2,
      livecrawl: "always"
    )
    service.call

    assert_requested :post, "https://api.exa.ai/contents"
  end

  def test_call_handles_text_as_boolean
    stub_request(:post, "https://api.exa.ai/contents")
      .with(body: hash_including(text: true))
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::GetContents.new(@connection, urls: ["https://example.com"], text: true)
    service.call

    assert_requested :post, "https://api.exa.ai/contents"
  end

  def test_call_handles_text_as_object
    stub_request(:post, "https://api.exa.ai/contents")
      .with(body: hash_including(text: { maxCharacters: 1000 }))
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::GetContents.new(
      @connection,
      urls: ["https://example.com"],
      text: { maxCharacters: 1000 }
    )
    service.call

    assert_requested :post, "https://api.exa.ai/contents"
  end
end
