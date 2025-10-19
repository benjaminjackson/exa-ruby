# frozen_string_literal: true

require "test_helper"

class AnswerTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
  end

  def test_initialize_with_connection_and_params
    service = Exa::Services::Answer.new(@connection, query: "What is SpaceX valuation?")

    assert_instance_of Exa::Services::Answer, service
  end

  def test_call_posts_to_answer_endpoint
    stub_request(:post, "https://api.exa.ai/answer")
      .with(body: hash_including(query: "What is SpaceX valuation?"))
      .to_return(
        status: 200,
        body: { answer: "Test answer", citations: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Answer.new(@connection, query: "What is SpaceX valuation?")
    service.call

    assert_requested :post, "https://api.exa.ai/answer"
  end

  def test_call_includes_query_parameter
    stub_request(:post, "https://api.exa.ai/answer")
      .with(body: hash_including(query: "What is SpaceX valuation?"))
      .to_return(
        status: 200,
        body: { answer: "Test", citations: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Answer.new(@connection, query: "What is SpaceX valuation?")
    service.call

    assert_requested :post, "https://api.exa.ai/answer",
      body: hash_including(query: "What is SpaceX valuation?")
  end

  def test_call_includes_text_parameter
    stub_request(:post, "https://api.exa.ai/answer")
      .with(body: hash_including(query: "test query", text: true))
      .to_return(
        status: 200,
        body: { answer: "Test", citations: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Answer.new(@connection, query: "test query", text: true)
    service.call

    assert_requested :post, "https://api.exa.ai/answer",
      body: hash_including(text: true)
  end

  def test_call_returns_answer_object
    stub_request(:post, "https://api.exa.ai/answer")
      .to_return(
        status: 200,
        body: {
          answer: "$350 billion",
          citations: [
            { title: "SpaceX Valuation", url: "https://example.com" }
          ],
          costDollars: { answer: 0.01, search: 0.005 }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Answer.new(@connection, query: "test")
    result = service.call

    assert_instance_of Exa::Resources::Answer, result
    assert_equal "$350 billion", result.answer
    assert_equal 1, result.citations.length
    assert_equal({ "answer" => 0.01, "search" => 0.005 }, result.cost_dollars)
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:post, "https://api.exa.ai/answer")
      .to_return(
        status: 401,
        body: { error: "Invalid API key" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Answer.new(@connection, query: "test")

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end

  def test_call_raises_server_error_on_500
    stub_request(:post, "https://api.exa.ai/answer")
      .to_return(
        status: 500,
        body: { error: "Internal server error" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::Answer.new(@connection, query: "test")

    assert_raises(Exa::InternalServerError) do
      service.call
    end
  end
end
