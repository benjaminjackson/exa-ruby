# frozen_string_literal: true

require "test_helper"

class SearchStreamTest < Minitest::Test
  OUTPUT_SCHEMA = {
    "type" => "object",
    "properties" => { "lead_investor" => { "type" => "string" } }
  }.freeze

  def test_call_yields_each_chunk_in_order_and_skips_done_marker
    events = [
      { "type" => "text-delta", "delta" => "Sequoia" },
      { "type" => "grounding", "grounding" => [] },
      { "type" => "results", "results" => [{ "url" => "https://www.anthropic.com/news" }] },
      { "type" => "done", "requestId" => "req_1" }
    ]
    sse_body = events.map { |event| "data: #{JSON.generate(event)}\n\n" }.join + "data: [DONE]\n\n"
    connection = streaming_connection(sse_body)

    chunks = []
    Exa::Services::SearchStream.new(
      connection,
      query: "Who led the latest Anthropic funding round?",
      output_schema: OUTPUT_SCHEMA
    ).call { |chunk| chunks << chunk }

    assert_equal %w[text-delta grounding results done], chunks.map { |chunk| chunk["type"] }
  end

  def test_call_raises_exa_error_on_error_chunk
    sse_body = "data: #{JSON.generate({ 'type' => 'error', 'error' => { 'message' => 'Synthesis failed' } })}\n\n"
    connection = streaming_connection(sse_body)

    error = assert_raises(Exa::Error) do
      Exa::Services::SearchStream.new(
        connection,
        query: "Who led the latest Anthropic funding round?",
        output_schema: OUTPUT_SCHEMA
      ).call { |_chunk| }
    end

    assert_equal "Synthesis failed", error.message
  end

  def test_call_posts_stream_true_with_converted_params_to_search
    posted_body = nil
    stub_request(:post, "https://api.exa.ai/search")
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(status: 200, body: "data: [DONE]\n\n", headers: { "Content-Type" => "text/event-stream" })

    Exa::Services::SearchStream.new(
      Exa::Connection.build(api_key: "test_key"),
      query: "Who led the latest Anthropic funding round?",
      output_schema: OUTPUT_SCHEMA,
      num_results: 3,
      text: true
    ).call { |_chunk| }

    assert_equal true, posted_body["stream"]
    assert_equal "auto", posted_body["type"]
    assert_equal 3, posted_body["numResults"]
    assert_equal OUTPUT_SCHEMA, posted_body["outputSchema"]
    assert_equal true, posted_body.dig("contents", "text")
  end

  def test_call_sends_exa_beta_header_for_dynamic_highlights
    stub_request(:post, "https://api.exa.ai/search")
      .to_return(status: 200, body: "data: [DONE]\n\n", headers: { "Content-Type" => "text/event-stream" })

    Exa::Services::SearchStream.new(
      Exa::Connection.build(api_key: "test_key"),
      query: "Who led the latest Anthropic funding round?",
      output_schema: OUTPUT_SCHEMA,
      highlights: { dynamic: true }
    ).call { |_chunk| }

    assert_requested :post, "https://api.exa.ai/search", headers: { "Exa-Beta" => "dynamic-highlights-2026-08-28" }
  end

  def test_raises_argument_error_without_output_schema
    assert_raises(ArgumentError) do
      Exa::Services::SearchStream.new(Exa::Connection.build(api_key: "test_key"), query: "Who led the latest Anthropic funding round?")
    end
  end

  def test_raises_argument_error_on_invalid_search_type
    assert_raises(ArgumentError) do
      Exa::Services::SearchStream.new(
        Exa::Connection.build(api_key: "test_key"),
        query: "Who led the latest Anthropic funding round?",
        output_schema: OUTPUT_SCHEMA,
        type: "keyword"
      )
    end
  end

  def test_client_search_stream_yields_chunks
    stub_request(:post, "https://api.exa.ai/search")
      .to_return(
        status: 200,
        body: "data: #{JSON.generate({ 'type' => 'done' })}\n\ndata: [DONE]\n\n",
        headers: { "Content-Type" => "text/event-stream" }
      )
    client = Exa::Client.new(api_key: "test_key")

    chunks = []
    client.search_stream("Who led the latest Anthropic funding round?", output_schema: OUTPUT_SCHEMA) { |chunk| chunks << chunk }

    assert_equal [{ "type" => "done" }], chunks
  end

  private

  # Builds a connection whose /search stub feeds the given server-sent event
  # body through the on_data callback, the way a real stream arrives.
  def streaming_connection(sse_body)
    Faraday.new(url: "https://api.exa.ai") do |faraday|
      faraday.request :json
      faraday.response :raise_error
      faraday.response :json, content_type: /\bjson$/
      faraday.adapter :test do |stub|
        stub.post("/search") do |env|
          env.request.on_data&.call(sse_body)
          [200, { "Content-Type" => "text/event-stream" }, ""]
        end
      end
    end
  end
end
