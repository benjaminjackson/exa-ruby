require "test_helper"

class AnswerStreamTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
  end

  def test_initialize_with_connection_and_params
    service = Exa::Services::AnswerStream.new(@connection, query: "test query")

    assert_instance_of Exa::Services::AnswerStream, service
  end

  def test_call_yields_answer_chunks_in_real_time
    # Simulate streaming with on_data callback to test real-time delivery
    chunk1 = {
      "choices" => [{ "delta" => { "role" => "assistant", "content" => "Hello " } }]
    }
    chunk2 = {
      "choices" => [{ "delta" => { "role" => "assistant", "content" => "world" } }]
    }

    # Create connection with test adapter for streaming
    connection = Faraday.new(url: "https://api.exa.ai") do |faraday|
      faraday.request :authorization, "Bearer", "test_key"
      faraday.request :json
      faraday.response :raise_error
      faraday.response :json, content_type: /\bjson$/

      # Mock adapter that simulates streaming via on_data callback
      faraday.adapter :test do |stub|
        stub.post("/answer") do |env|
          # env.request is a Faraday::RequestOptions with on_data member
          on_data = env.request.on_data
          if on_data
            # Simulate streaming: deliver chunks incrementally
            on_data.call("data: #{JSON.generate(chunk1)}\n\n")
            on_data.call("data: #{JSON.generate(chunk2)}\n\n")
          end

          [
            200,
            { "Content-Type" => "text/event-stream" },
            ""
          ]
        end
      end
    end

    service = Exa::Services::AnswerStream.new(connection, query: "test query")

    chunks = []
    service.call { |chunk| chunks << chunk }

    assert_equal 2, chunks.length
    assert_equal "Hello ", chunks[0]["choices"][0]["delta"]["content"]
    assert_equal "world", chunks[1]["choices"][0]["delta"]["content"]
  end
end
