require "test_helper"

class AnswerStreamTest < Minitest::Test
  def setup
    super
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

  def test_call_yields_crlf_chunks_in_real_time
    contents = ["Ruby ", "3.4 ", "ships YJIT"]
    frames = contents.each_with_index.map do |content, index|
      chunk = { "choices" => [{ "delta" => { "role" => "assistant", "content" => content } }] }
      "id: #{index + 1}\r\ndata: #{JSON.generate(chunk)}\r\n\r\n"
    end
    # The third frame is split between the "\r" and the "\n" of its id line.
    pieces = [frames[0], frames[1] + "id: 3\r", frames[2].delete_prefix("id: 3\r")]

    chunks = []
    counts_before_each_piece = []
    connection = Faraday.new(url: "https://api.exa.ai") do |faraday|
      faraday.request :json
      faraday.adapter :test do |stub|
        stub.post("/answer") do |env|
          pieces.each do |piece|
            counts_before_each_piece << chunks.length
            env.request.on_data.call(piece, 0, env)
          end
          [200, { "Content-Type" => "text/event-stream" }, ""]
        end
      end
    end

    Exa::Services::AnswerStream.new(connection, query: "What changed in the Ruby 3.4 release?")
                               .call { |chunk| chunks << chunk }

    assert_equal [0, 1, 2], counts_before_each_piece
    assert_equal contents, chunks.map { |chunk| chunk["choices"][0]["delta"]["content"] }
  end

  def test_call_raises_with_api_message_on_error_status
    stub_request(:post, "https://api.exa.ai/answer")
      .to_return(
        status: 410,
        body: %q({"error":"This endpoint has been retired"}),
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AnswerStream.new(@connection, query: "What is the latest valuation of SpaceX?")

    error = assert_raises(Exa::ClientError) { service.call { |_chunk| } }

    assert_equal "This endpoint has been retired", error.message
  end

  def test_call_posts_snake_case_params_as_camel_case_keys
    stub_request(:post, "https://api.exa.ai/answer")
      .to_return(status: 200, body: "data: {}\n\n", headers: { "Content-Type" => "text/event-stream" })
    output_schema = { "type" => "object", "properties" => { "lead_investor" => { "type" => "string" } } }

    Exa::Services::AnswerStream.new(
      @connection,
      query: "Who led the Series A for Anthropic?",
      system_prompt: "Answer in one sentence",
      output_schema: output_schema
    ).call { |_chunk| }

    assert_requested(:post, "https://api.exa.ai/answer") do |request|
      body = JSON.parse(request.body)
      assert_equal true, body["stream"]
      assert_equal "Answer in one sentence", body["systemPrompt"]
      assert_equal output_schema, body["outputSchema"]
      assert_empty snake_case_keys(body)
    end
  end

  def test_call_raises_exa_error_on_error_chunk
    error_chunk = { "tag" => "ERROR", "payload" => { "error" => { "code" => "INTERNAL", "message" => "Answer generation failed" } } }
    stub_request(:post, "https://api.exa.ai/answer")
      .to_return(status: 200, body: "data: #{JSON.generate(error_chunk)}\n\n", headers: { "Content-Type" => "text/event-stream" })

    service = Exa::Services::AnswerStream.new(@connection, query: "What is the latest valuation of SpaceX?")

    error = assert_raises(Exa::Error) { service.call { |_chunk| } }

    assert_equal "Answer generation failed", error.message
  end

  def test_call_passes_through_chunks_that_are_not_objects
    stub_request(:post, "https://api.exa.ai/answer")
      .to_return(status: 200, body: "data: [1,2]\n\ndata: 42\n\ndata: null\n\ndata: true\n\n", headers: { "Content-Type" => "text/event-stream" })

    chunks = []
    Exa::Services::AnswerStream.new(@connection, query: "What is the latest valuation of SpaceX?").call { |chunk| chunks << chunk }

    assert_equal [[1, 2], 42, nil, true], chunks
  end

  def test_call_error_chunk_without_message_uses_chunk_json_as_message
    error_chunk = { "tag" => "ERROR", "payload" => { "error" => { "code" => "INTERNAL" } } }
    stub_request(:post, "https://api.exa.ai/answer")
      .to_return(status: 200, body: "data: #{JSON.generate(error_chunk)}\n\n", headers: { "Content-Type" => "text/event-stream" })

    service = Exa::Services::AnswerStream.new(@connection, query: "What is the latest valuation of SpaceX?")

    error = assert_raises(Exa::Error) { service.call { |_chunk| } }

    assert_equal JSON.generate(error_chunk), error.message
  end

  def test_call_yields_each_data_line_of_a_frame_as_its_own_chunk
    stub_request(:post, "https://api.exa.ai/answer")
      .to_return(status: 200, body: "data: {\"a\":1}\ndata: {\"b\":2}\n\n", headers: { "Content-Type" => "text/event-stream" })

    chunks = []
    Exa::Services::AnswerStream.new(@connection, query: "What is the latest valuation of SpaceX?").call { |chunk| chunks << chunk }

    assert_equal [{ "a" => 1 }, { "b" => 2 }], chunks
  end

  def test_call_keeps_good_data_line_after_bad_one_in_same_frame
    stub_request(:post, "https://api.exa.ai/answer")
      .to_return(status: 200, body: "data: nope\ndata: {\"a\":1}\n\n", headers: { "Content-Type" => "text/event-stream" })

    chunks = []
    Exa::Services::AnswerStream.new(@connection, query: "What is the latest valuation of SpaceX?").call { |chunk| chunks << chunk }

    assert_equal [{ "a" => 1 }], chunks
  end

  def test_call_yields_chunk_then_raises_on_error_line_in_same_frame
    error_chunk = { "type" => "error", "error" => { "message" => "Answer generation failed" } }
    stub_request(:post, "https://api.exa.ai/answer")
      .to_return(status: 200, body: "data: {\"a\":1}\ndata: #{JSON.generate(error_chunk)}\n\n",
                 headers: { "Content-Type" => "text/event-stream" })

    chunks = []
    service = Exa::Services::AnswerStream.new(@connection, query: "What is the latest valuation of SpaceX?")

    error = assert_raises(Exa::Error) { service.call { |chunk| chunks << chunk } }

    assert_equal [{ "a" => 1 }], chunks
    assert_equal "Answer generation failed", error.message
  end

  def test_call_yields_chunk_when_frame_end_is_split_inside_blank_line
    # The first frame's closing "\r\n\r\n" arrives as "\r\n\r" and then "\n".
    pieces = ["data: {\"a\":1}\r\n\r", "\n", "data: {\"b\":2}\r\n\r\n"]

    chunks = []
    counts_before_each_piece = []
    connection = Faraday.new(url: "https://api.exa.ai") do |faraday|
      faraday.request :json
      faraday.adapter :test do |stub|
        stub.post("/answer") do |env|
          pieces.each do |piece|
            counts_before_each_piece << chunks.length
            env.request.on_data.call(piece, 0, env)
          end
          [200, { "Content-Type" => "text/event-stream" }, ""]
        end
      end
    end

    Exa::Services::AnswerStream.new(connection, query: "What changed in the Ruby 3.4 release?")
                               .call { |chunk| chunks << chunk }

    assert_equal 1, counts_before_each_piece.last
    assert_equal [{ "a" => 1 }, { "b" => 2 }], chunks
  end
end
