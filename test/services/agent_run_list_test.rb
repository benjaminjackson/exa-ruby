require "test_helper"
require_relative "../../lib/exa/services/agent_run_list"

class AgentRunListTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
  end

  def test_initialize_with_connection_and_params
    service = Exa::Services::AgentRunList.new(@connection, limit: 10)

    assert_instance_of Exa::Services::AgentRunList, service
  end

  def test_call_gets_from_agent_runs_endpoint
    stub_request(:get, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunList.new(@connection)
    service.call

    assert_requested :get, "https://api.exa.ai/agent/runs"
  end

  def test_call_includes_limit_parameter
    stub_request(:get, "https://api.exa.ai/agent/runs?limit=25")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunList.new(@connection, limit: 25)
    service.call

    assert_requested :get, "https://api.exa.ai/agent/runs?limit=25"
  end

  def test_call_includes_cursor_parameter
    stub_request(:get, "https://api.exa.ai/agent/runs?cursor=abc123")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunList.new(@connection, cursor: "abc123")
    service.call

    assert_requested :get, "https://api.exa.ai/agent/runs?cursor=abc123"
  end

  def test_call_returns_agent_run_list_object
    stub_request(:get, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunList.new(@connection)
    result = service.call

    assert_instance_of Exa::Resources::AgentRunList, result
  end

  def test_call_maps_data_array_to_agent_run_objects
    run_data = {
      id: "run_abc123",
      object: "agent_run",
      status: "completed",
      createdAt: 1234567890,
      completedAt: 1234568000
    }

    stub_request(:get, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 200,
        body: { data: [run_data], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunList.new(@connection)
    result = service.call

    assert_equal 1, result.data.length
    assert_instance_of Exa::Resources::AgentRun, result.data.first
    assert_equal "run_abc123", result.data.first.id
    assert_equal "completed", result.data.first.status
  end

  def test_call_handles_has_more_true
    stub_request(:get, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 200,
        body: { data: [], hasMore: true, nextCursor: "next456" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunList.new(@connection)
    result = service.call

    assert_equal true, result.has_more
  end

  def test_call_handles_has_more_false
    stub_request(:get, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunList.new(@connection)
    result = service.call

    assert_equal false, result.has_more
  end

  def test_call_handles_next_cursor_present
    stub_request(:get, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 200,
        body: { data: [], hasMore: true, nextCursor: "next456" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunList.new(@connection)
    result = service.call

    assert_equal "next456", result.next_cursor
  end

  def test_call_handles_next_cursor_null
    stub_request(:get, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunList.new(@connection)
    result = service.call

    assert_nil result.next_cursor
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:get, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 401,
        body: { error: "Unauthorized" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunList.new(@connection)

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end

  def test_call_raises_server_error_on_500
    stub_request(:get, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 500,
        body: { error: "Internal server error" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunList.new(@connection)

    assert_raises(Exa::InternalServerError) do
      service.call
    end
  end
end
