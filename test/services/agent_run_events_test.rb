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

  def test_call_with_last_event_id_replays_events_over_sse
    sse_body = "id: 8\r\nevent: agent_run.started\r\ndata: {\"status\":\"running\"}\r\n\r\n" \
               ": keep-alive\r\n\r\n" \
               "id: 9\r\nevent: agent_run.completed\r\ndata: {\"status\":\"completed\"}\r\n\r\n"
    stub_request(:get, "https://api.exa.ai/agent/runs/#{@run_id}/events")
      .with(headers: { "Accept" => "text/event-stream", "Last-Event-ID" => "7" })
      .to_return(status: 200, body: sse_body, headers: { "Content-Type" => "text/event-stream" })

    result = Exa::Services::AgentRunEvents.new(@connection, run_id: @run_id, last_event_id: "7").call

    assert_requested :get, "https://api.exa.ai/agent/runs/#{@run_id}/events",
                     headers: { "Accept" => "text/event-stream", "Last-Event-ID" => "7" }
    assert_instance_of Exa::Resources::AgentRunEventList, result
    assert_equal [
      { "id" => "8", "event" => "agent_run.started", "data" => { "status" => "running" } },
      { "id" => "9", "event" => "agent_run.completed", "data" => { "status" => "completed" } }
    ], result.data
    assert_equal false, result.has_more
    assert_nil result.next_cursor
  end

  def test_call_without_last_event_id_sends_no_last_event_id_header
    stub_request(:get, "https://api.exa.ai/agent/runs/#{@run_id}/events")
      .to_return(
        status: 200,
        body: { "object" => "list", "data" => [], "hasMore" => false, "nextCursor" => nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    Exa::Services::AgentRunEvents.new(@connection, run_id: @run_id).call

    assert_requested(:get, "https://api.exa.ai/agent/runs/#{@run_id}/events") do |request|
      !request.headers.key?("Last-Event-Id") && request.headers["Accept"] != "text/event-stream"
    end
  end

  def test_call_with_last_event_id_reads_json_body_when_server_ignores_accept
    events = [{ "id" => "8", "event" => "agent_run.started", "data" => { "status" => "running" } }]
    stub_request(:get, "https://api.exa.ai/agent/runs/#{@run_id}/events")
      .with(headers: { "Accept" => "text/event-stream", "Last-Event-ID" => "7" })
      .to_return(
        status: 200,
        body: { "object" => "list", "data" => events, "hasMore" => true, "nextCursor" => "cur_next" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = Exa::Services::AgentRunEvents.new(@connection, run_id: @run_id, last_event_id: "7").call

    assert_equal events, result.data
    assert_equal true, result.has_more
    assert_equal "cur_next", result.next_cursor
  end
end
