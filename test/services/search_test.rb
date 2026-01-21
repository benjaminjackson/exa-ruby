require "test_helper"

class SearchTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
  end

  def test_initialize_with_connection_and_params
    service = Exa::Services::Search.new(@connection, query: "test query")

    assert_instance_of Exa::Services::Search, service
  end

  def test_sets_default_search_type_to_auto
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "test",
          type: "auto"
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(@connection, query: "test")
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_raises_error_on_invalid_search_type
    assert_raises(ArgumentError) do
      Exa::Services::Search.new(@connection, query: "test", type: "neural")
    end

    assert_raises(ArgumentError) do
      Exa::Services::Search.new(@connection, query: "test", type: "invalid")
    end
  end

  def test_call_posts_to_search_endpoint
    stub_request(:post, "https://api.exa.ai/search")
      .with(body: hash_including(query: "ruby programming"))
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(@connection, query: "ruby programming")
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_call_returns_search_result_object
    stub_request(:post, "https://api.exa.ai/search")
      .to_return(
        status: 200,
        body: {
          results: [
            { title: "Test Result", url: "https://example.com", score: 0.95 }
          ],
          requestId: "abc123",
          resolvedSearchType: "fast"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(@connection, query: "test")
    result = service.call

    assert_instance_of Exa::Resources::SearchResult, result
    assert_equal 1, result.results.length
    assert_equal "abc123", result.request_id
    assert_equal "fast", result.resolved_search_type
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:post, "https://api.exa.ai/search")
      .to_return(
        status: 401,
        body: { error: "Invalid API key" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(@connection, query: "test")

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end

  def test_call_raises_server_error_on_500
    stub_request(:post, "https://api.exa.ai/search")
      .to_return(
        status: 500,
        body: { error: "Internal server error" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(@connection, query: "test")

    assert_raises(Exa::InternalServerError) do
      service.call
    end
  end

  def test_call_sends_all_search_parameters
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
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(
      @connection,
      query: "AI research",
      type: "deep",
      numResults: 20,
      category: "research paper"
    )
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_call_sends_people_category
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "John Smith software engineer",
          category: "people"
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(
      @connection,
      query: "John Smith software engineer",
      category: "people"
    )
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_call_sends_company_category
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "Anthropic AI safety",
          category: "company"
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(
      @connection,
      query: "Anthropic AI safety",
      category: "company"
    )
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_call_converts_date_range_parameters
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "test",
          startPublishedDate: "2025-10-12T04:00:00.000Z",
          endPublishedDate: "2025-10-20T03:59:59.999Z",
          startCrawlDate: "2025-10-12T04:00:00.000Z",
          endCrawlDate: "2025-10-20T03:59:59.999Z"
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(
      @connection,
      query: "test",
      start_published_date: "2025-10-12T04:00:00.000Z",
      end_published_date: "2025-10-20T03:59:59.999Z",
      start_crawl_date: "2025-10-12T04:00:00.000Z",
      end_crawl_date: "2025-10-20T03:59:59.999Z"
    )
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_call_converts_text_filter_parameters
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "test",
          includeText: ["peer-reviewed"],
          excludeText: ["paid-partnership"]
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(
      @connection,
      query: "test",
      include_text: ["peer-reviewed"],
      exclude_text: ["paid-partnership"]
    )
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_call_handles_contents_text_as_boolean
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "test",
          contents: { text: true }
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(
      @connection,
      query: "test",
      text: true
    )
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_call_handles_contents_text_as_hash
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "test",
          contents: {
            text: {
              maxCharacters: 3000,
              includeHtmlTags: true
            }
          }
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(
      @connection,
      query: "test",
      text: {
        max_characters: 3000,
        include_html_tags: true
      }
    )
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_call_handles_contents_summary_as_boolean
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "test",
          contents: { summary: true }
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(
      @connection,
      query: "test",
      summary: true
    )
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_call_handles_contents_summary_as_hash
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "test",
          contents: {
            summary: {
              query: "Main points",
              schema: { type: "object", properties: {} }
            }
          }
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(
      @connection,
      query: "test",
      summary: {
        query: "Main points",
        schema: { type: "object", properties: {} }
      }
    )
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_call_handles_contents_context_as_boolean
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "test",
          contents: { context: true }
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(
      @connection,
      query: "test",
      context: true
    )
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_call_handles_contents_context_as_hash
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "test",
          contents: {
            context: {
              maxCharacters: 5000
            }
          }
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(
      @connection,
      query: "test",
      context: {
        max_characters: 5000
      }
    )
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_call_handles_subpage_crawling
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "test",
          contents: {
            subpages: 1,
            subpageTarget: ["about", "pricing"]
          }
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(
      @connection,
      query: "test",
      subpages: 1,
      subpage_target: ["about", "pricing"]
    )
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end

  def test_call_handles_links_and_image_links_extraction
    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: hash_including(
          query: "test",
          contents: {
            extras: {
              links: 3,
              imageLinks: 3
            }
          }
        )
      )
      .to_return(
        status: 200,
        body: { results: [], requestId: "test123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Search.new(
      @connection,
      query: "test",
      extras: {
        links: 3,
        image_links: 3
      }
    )
    service.call

    assert_requested :post, "https://api.exa.ai/search"
  end
end
