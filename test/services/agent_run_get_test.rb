require "test_helper"
require_relative "../../lib/exa/services/agent_run_get"

class AgentRunGetTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
  end

  def test_initialize_with_connection_and_id
    service = Exa::Services::AgentRunGet.new(@connection, run_id: "run_abc123")

    assert_instance_of Exa::Services::AgentRunGet, service
  end

  def test_call_gets_from_agent_runs_by_id_endpoint
    stub_request(:get, "https://api.exa.ai/agent/runs/run_abc123")
      .to_return(
        status: 200,
        body: { id: "run_abc123", object: "agent_run", status: "queued" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunGet.new(@connection, run_id: "run_abc123")
    service.call

    assert_requested :get, "https://api.exa.ai/agent/runs/run_abc123"
  end

  def test_call_includes_id_in_path
    stub_request(:get, "https://api.exa.ai/agent/runs/run_xyz999")
      .to_return(
        status: 200,
        body: { id: "run_xyz999", object: "agent_run", status: "running" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunGet.new(@connection, run_id: "run_xyz999")
    service.call

    assert_requested :get, "https://api.exa.ai/agent/runs/run_xyz999"
  end

  def test_call_returns_agent_run_object
    stub_request(:get, "https://api.exa.ai/agent/runs/run_abc123")
      .to_return(
        status: 200,
        body: {
          id: "run_abc123",
          object: "agent_run",
          status: "completed",
          createdAt: 1234567890,
          completedAt: 1234568000
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunGet.new(@connection, run_id: "run_abc123")
    result = service.call

    assert_instance_of Exa::Resources::AgentRun, result
    assert_equal "run_abc123", result.id
    assert_equal "agent_run", result.object
    assert_equal "completed", result.status
    assert_equal 1234567890, result.created_at
    assert_equal 1234568000, result.completed_at
  end

  def test_call_maps_all_fields_from_response
    stub_request(:get, "https://api.exa.ai/agent/runs/run_abc123")
      .to_return(
        status: 200,
        body: {
          id: "run_abc123",
          object: "agent_run",
          status: "completed",
          stopReason: "end_turn",
          createdAt: 1234567890,
          completedAt: 1234568000,
          request: { query: "Find AI startups" },
          output: { text: "Here are the results..." },
          usage: { input_tokens: 100, output_tokens: 200 },
          costDollars: { total: 0.05 }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunGet.new(@connection, run_id: "run_abc123")
    result = service.call

    assert_equal "end_turn", result.stop_reason
    refute_nil result.request
    refute_nil result.output
    refute_nil result.usage
    assert_equal 0.05, result.cost_dollars["total"]
  end

  def test_call_handles_running_status
    stub_request(:get, "https://api.exa.ai/agent/runs/run_abc123")
      .to_return(
        status: 200,
        body: { id: "run_abc123", object: "agent_run", status: "running" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunGet.new(@connection, run_id: "run_abc123")
    result = service.call

    assert result.running?
  end

  def test_call_handles_failed_status
    stub_request(:get, "https://api.exa.ai/agent/runs/run_abc123")
      .to_return(
        status: 200,
        body: { id: "run_abc123", object: "agent_run", status: "failed" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunGet.new(@connection, run_id: "run_abc123")
    result = service.call

    assert result.failed?
    assert result.finished?
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:get, "https://api.exa.ai/agent/runs/run_abc123")
      .to_return(
        status: 401,
        body: { error: "Unauthorized" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunGet.new(@connection, run_id: "run_abc123")

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end

  def test_call_raises_not_found_on_404
    stub_request(:get, "https://api.exa.ai/agent/runs/run_abc123")
      .to_return(
        status: 404,
        body: { error: "Agent run not found" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunGet.new(@connection, run_id: "run_abc123")

    assert_raises(Exa::NotFound) do
      service.call
    end
  end
end
