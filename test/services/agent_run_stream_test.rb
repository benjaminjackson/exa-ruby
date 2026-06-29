require "test_helper"
require_relative "../../lib/exa/services/agent_run_stream"
require_relative "../../lib/exa/services/parameter_converter"

class AgentRunStreamTest < Minitest::Test
  def test_initialize_with_connection_and_params
    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::AgentRunStream.new(connection, system_prompt: "You are helpful")

    assert_instance_of Exa::Services::AgentRunStream, service
  end

  def test_call_requires_block
    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::AgentRunStream.new(connection, system_prompt: "You are helpful")

    assert_raises(ArgumentError) { service.call }
  end

  def test_call_yields_event_and_data_pairs
    frame1 = { "id" => "run_123", "status" => "queued" }
    frame2 = { "id" => "run_123", "status" => "completed", "output" => { "text" => "Done." } }

    request_headers = {}

    connection = Faraday.new(url: "https://api.exa.ai") do |faraday|
      faraday.request :authorization, "Bearer", "test_key"
      faraday.request :json
      faraday.response :raise_error
      faraday.response :json, content_type: /\bjson$/

      faraday.adapter :test do |stub|
        stub.post("/agent/runs") do |env|
          request_headers.merge!(env.request_headers)

          on_data = env.request.on_data
          if on_data
            on_data.call("event: agent_run.created\ndata: #{JSON.generate(frame1)}\n\n")
            on_data.call("event: agent_run.completed\ndata: #{JSON.generate(frame2)}\n\n")
          end

          [200, { "Content-Type" => "text/event-stream" }, ""]
        end
      end
    end

    service = Exa::Services::AgentRunStream.new(connection, system_prompt: "You are helpful")

    events = []
    service.call { |event, data| events << [event, data] }

    assert_equal "text/event-stream", request_headers["Accept"]

    assert_equal 2, events.length

    assert_equal "agent_run.created", events[0][0]
    assert_equal frame1, events[0][1]

    assert_equal "agent_run.completed", events[1][0]
    assert_equal frame2, events[1][1]
  end

  def test_call_converts_snake_case_params
    captured_body = nil

    connection = Faraday.new(url: "https://api.exa.ai") do |faraday|
      faraday.request :authorization, "Bearer", "test_key"
      faraday.request :json
      faraday.response :raise_error
      faraday.response :json, content_type: /\bjson$/

      faraday.adapter :test do |stub|
        stub.post("/agent/runs") do |env|
          captured_body = JSON.parse(env.body)

          on_data = env.request.on_data
          on_data&.call("event: agent_run.completed\ndata: {\"id\":\"run_1\",\"status\":\"completed\"}\n\n")

          [200, { "Content-Type" => "text/event-stream" }, ""]
        end
      end
    end

    service = Exa::Services::AgentRunStream.new(
      connection,
      system_prompt: "You are helpful",
      previous_run_id: "run_prev_123"
    )

    service.call { |_event, _data| }

    assert_equal "You are helpful", captured_body["systemPrompt"]
    assert_equal "run_prev_123", captured_body["previousRunId"]
  end
end
