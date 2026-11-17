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

  def test_call_posts_snake_case_params_as_camel_case_keys
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    Exa::Services::FindSimilar.new(
      @connection,
      url: "https://example.com",
      num_results: 5,
      start_published_date: "2025-01-01",
      end_published_date: "2025-06-30",
      include_text: ["Series A"],
      exclude_domains: ["example.org"]
    ).call

    assert_requested(:post, "https://api.exa.ai/findSimilar") do |request|
      body = JSON.parse(request.body)
      assert_equal 5, body["numResults"]
      assert_equal "2025-01-01", body["startPublishedDate"]
      assert_equal "2025-06-30", body["endPublishedDate"]
      assert_equal ["Series A"], body["includeText"]
      assert_equal ["example.org"], body["excludeDomains"]
      assert_empty snake_case_keys(body)
    end
  end

  def test_call_posts_text_and_summary_under_contents
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    Exa::Services::FindSimilar.new(
      @connection,
      url: "https://example.com",
      text: { max_characters: 500 },
      summary: { query: "What does this company build?" }
    ).call

    assert_requested(:post, "https://api.exa.ai/findSimilar") do |request|
      body = JSON.parse(request.body)
      refute body.key?("text")
      refute body.key?("summary")
      assert_equal({ "maxCharacters" => 500 }, body["contents"]["text"])
      assert_equal({ "query" => "What does this company build?" }, body["contents"]["summary"])
    end
  end

  def test_call_merges_contents_hash_with_content_params
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    Exa::Services::FindSimilar.new(
      @connection,
      url: "https://example.com",
      contents: { text: { include_html_tags: true } },
      summary: true
    ).call

    assert_requested(:post, "https://api.exa.ai/findSimilar") do |request|
      body = JSON.parse(request.body)
      assert_equal({ "text" => { "includeHtmlTags" => true }, "summary" => true }, body["contents"])
    end
  end

  def test_call_folds_snapshot_as_of_under_contents
    posted_body = nil
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    Exa::Services::FindSimilar.new(@connection, url: "https://www.anthropic.com/research", snapshot_as_of: "2026-01-01T00:00:00Z").call

    assert_equal "2026-01-01T00:00:00Z", posted_body.dig("contents", "snapshotAsOf")
  end
end
