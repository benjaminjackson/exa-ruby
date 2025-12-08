# frozen_string_literal: true

require "test_helper"

class AnswerStreamIntegrationTest < Minitest::Test
  def setup
    skip_unless_integration_enabled
  end

  def test_answer_stream_yields_chunks
    VCR.use_cassette("answer_stream_spacex_valuation") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      chunks = []

      client.answer_stream("What is the latest valuation of SpaceX?", text: true) do |chunk|
        chunks << chunk
      end

      refute_empty chunks
      assert chunks.all? { |chunk| chunk.is_a?(Hash) }
      # Verify we got content chunks (they have choices with delta content)
      assert chunks.any? { |chunk| chunk.dig("choices", 0, "delta", "content") }
    end
  end

  def test_answer_stream_with_structured_output
    VCR.use_cassette("answer_stream_structured_output") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      chunks = []

      schema = {
        "type" => "object",
        "properties" => {
          "company" => { "type" => "string" },
          "valuation" => { "type" => "string" }
        }
      }

      client.answer_stream(
        "What is the latest valuation of SpaceX?",
        output_schema: schema
      ) do |chunk|
        chunks << chunk
      end

      refute_empty chunks
      assert chunks.any? { |chunk| chunk.is_a?(Hash) }
    end
  end

  def test_answer_stream_requires_block
    client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

    error = assert_raises(ArgumentError) do
      client.answer_stream("What is the latest valuation of SpaceX?")
    end

    assert_match(/block required/i, error.message)
  end
end
