require "test_helper"
require_relative "../../lib/exa/services/agent_run_delete"
require_relative "../../lib/exa/resources/agent_run"

class AgentRunDeleteTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
    @run_id = "run-abc123"
  end

  def test_initialize_with_connection_and_run_id
    service = Exa::Services::AgentRunDelete.new(@connection, run_id: @run_id)

    assert_instance_of Exa::Services::AgentRunDelete, service
  end

  def test_call_sends_delete_to_run_endpoint
    stub_request(:delete, "https://api.exa.ai/agent/runs/#{@run_id}")
      .to_return(
        status: 200,
        body: {
          id: @run_id,
          object: "agent_run",
          status: "deleted"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunDelete.new(@connection, run_id: @run_id)
    service.call

    assert_requested :delete, "https://api.exa.ai/agent/runs/#{@run_id}"
  end

  def test_call_returns_agent_run_on_200_with_body
    stub_request(:delete, "https://api.exa.ai/agent/runs/#{@run_id}")
      .to_return(
        status: 200,
        body: {
          id: @run_id,
          object: "agent_run",
          status: "deleted",
          createdAt: "2024-01-15T10:00:00Z"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunDelete.new(@connection, run_id: @run_id)
    result = service.call

    assert_instance_of Exa::Resources::AgentRun, result
    assert_equal @run_id, result.id
    assert_equal "agent_run", result.object
    assert_equal "deleted", result.status
  end

  def test_call_returns_agent_run_on_204_empty_body
    stub_request(:delete, "https://api.exa.ai/agent/runs/#{@run_id}")
      .to_return(
        status: 204,
        body: "",
        headers: {}
      )

    service = Exa::Services::AgentRunDelete.new(@connection, run_id: @run_id)
    result = service.call

    assert_instance_of Exa::Resources::AgentRun, result
    assert_equal @run_id, result.id
    assert_equal "agent_run", result.object
    assert_equal "deleted", result.status
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:delete, "https://api.exa.ai/agent/runs/#{@run_id}")
      .to_return(
        status: 401,
        body: { error: "Unauthorized" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunDelete.new(@connection, run_id: @run_id)

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end
end
