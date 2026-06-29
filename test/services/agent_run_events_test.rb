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
        body: { "object" => "list", "data" => [], "hasMore" => false, "nextCursor" => nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunEvents.new(@connection, run_id: @run_id)
    service.call

    assert_requested :get, "https://api.exa.ai/agent/runs/#{@run_id}/events"
  end

  def test_call_returns_paginated_event_list
    events = [
      { "id" => "1", "event" => "agent_run.created", "data" => { "status" => "queued" }, "createdAt" => "2024-01-15T10:00:01Z" },
      { "id" => "2", "event" => "agent_run.started", "data" => { "status" => "running" }, "createdAt" => "2024-01-15T10:00:02Z" }
    ]

    stub_request(:get, "https://api.exa.ai/agent/runs/#{@run_id}/events")
      .to_return(
        status: 200,
        body: { "object" => "list", "data" => events, "hasMore" => true, "nextCursor" => "cur_next" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunEvents.new(@connection, run_id: @run_id)
    result = service.call

    assert_instance_of Exa::Resources::AgentRunEventList, result
    assert_equal events, result.data
    assert_equal true, result.has_more
    assert_equal "cur_next", result.next_cursor
  end

  def test_call_passes_query_params_for_pagination
    stub_request(:get, "https://api.exa.ai/agent/runs/#{@run_id}/events")
      .with(query: { "cursor" => "cur_xyz", "limit" => "25" })
      .to_return(
        status: 200,
        body: { "object" => "list", "data" => [], "hasMore" => false, "nextCursor" => nil }.to_json,
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
