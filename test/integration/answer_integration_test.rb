# frozen_string_literal: true

require "test_helper"

class AnswerIntegrationTest < Minitest::Test
  def test_answer_returns_answer_with_citations
    VCR.use_cassette("answer_spacex_valuation") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.answer("What is the latest valuation of SpaceX?", text: true)

      assert_instance_of Exa::Resources::Answer, result
      refute_nil result.answer
      assert_instance_of Array, result.citations
    end
  end

  def test_answer_result_has_expected_structure
    VCR.use_cassette("answer_spacex_valuation") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.answer("What is the latest valuation of SpaceX?", text: true)

      assert_respond_to result, :answer
      assert_respond_to result, :citations
      assert_respond_to result, :cost_dollars
    end
  end
end
