require "test_helper"
require_relative "../../lib/exa/services/agent_run_events"

class AgentRunEventsTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
    @run_id = "run-abc123"
  end

  def test_initialize_with_connection_run_id_and_optional_params
    service = Exa::Services::AgentRunEvents.new(@connection, run_id: @run_id, cursor: "cur_xyz", limit: 50)

    assert_instance_of Exa::Services::AgentRunEvents, service
  end

  def test_call_gets_from_events_endpoint
    stub_request(:get, "https://api.exa.ai/agent/runs/#{@run_id}/events")
      .to_return(
        status: 200,
        body: [
          { "type" => "tool_use", "timestamp" => "2024-01-15T10:00:01Z" },
          { "type" => "tool_result", "timestamp" => "2024-01-15T10:00:02Z" }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunEvents.new(@connection, run_id: @run_id)
    service.call

    assert_requested :get, "https://api.exa.ai/agent/runs/#{@run_id}/events"
  end

  def test_call_returns_parsed_body_verbatim
    events = [
      { "type" => "tool_use", "timestamp" => "2024-01-15T10:00:01Z", "data" => { "tool" => "web_search" } },
      { "type" => "tool_result", "timestamp" => "2024-01-15T10:00:02Z", "data" => { "result" => "found results" } }
    ]

    stub_request(:get, "https://api.exa.ai/agent/runs/#{@run_id}/events")
      .to_return(
        status: 200,
        body: events.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunEvents.new(@connection, run_id: @run_id)
    result = service.call

    assert_equal events, result
  end

  def test_call_passes_query_params_for_pagination
    stub_request(:get, "https://api.exa.ai/agent/runs/#{@run_id}/events")
      .with(query: { "cursor" => "cur_xyz", "limit" => "25" })
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunEvents.new(@connection, run_id: @run_id, cursor: "cur_xyz", limit: 25)
    service.call

    assert_requested :get, "https://api.exa.ai/agent/runs/#{@run_id}/events",
                     query: { "cursor" => "cur_xyz", "limit" => "25" }
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:get, "https://api.exa.ai/agent/runs/#{@run_id}/events")
      .to_return(
        status: 401,
        body: { error: "Unauthorized" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunEvents.new(@connection, run_id: @run_id)

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end
end
