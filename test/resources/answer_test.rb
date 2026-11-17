# frozen_string_literal: true

require "test_helper"

class AnswerTest < Minitest::Test
  def test_initialize_with_answer_and_citations
    citations = [{ "title" => "Test", "url" => "https://example.com" }]
    result = Exa::Resources::Answer.new(
      answer: "SpaceX is valued at $350 billion",
      citations: citations
    )

    assert_instance_of Exa::Resources::Answer, result
    assert_equal "SpaceX is valued at $350 billion", result.answer
    assert_equal citations, result.citations
  end

  def test_initialize_with_optional_cost_dollars
    cost = { "answer" => 0.01, "search" => 0.005 }
    result = Exa::Resources::Answer.new(
      answer: "Test answer",
      citations: [],
      cost_dollars: cost
    )

    assert_equal cost, result.cost_dollars
  end

  def test_immutability
    result = Exa::Resources::Answer.new(
      answer: "Test",
      citations: []
    )

    assert_raises(FrozenError) do
      result.answer = "Changed"
    end
  end

  def test_to_h_method
    citations = [{ "title" => "Test" }]
    cost = { "answer" => 0.01 }
    result = Exa::Resources::Answer.new(
      answer: "Test answer",
      citations: citations,
      cost_dollars: cost
    )

    hash = result.to_h

    assert_equal "Test answer", hash[:answer]
    assert_equal citations, hash[:citations]
    assert_equal cost, hash[:cost_dollars]
  end

  def test_stubbed_response_exposes_request_id
    stub_request(:post, "https://api.exa.ai/answer")
      .to_return(status: 200, body: { answer: "About $350 billion", citations: [], requestId: "req_answer_1" }.to_json, headers: { "Content-Type" => "application/json" })
    connection = Exa::Connection.build(api_key: "test_key")

    result = Exa::Services::Answer.new(connection, query: "What is the latest valuation of SpaceX?").call

    assert_equal "req_answer_1", result.request_id
    assert_equal "req_answer_1", result.to_h[:request_id]
  end
end
