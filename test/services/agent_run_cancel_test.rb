require "test_helper"
require_relative "../../lib/exa/services/agent_run_cancel"
require_relative "../../lib/exa/resources/agent_run"

class AgentRunCancelTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
    @run_id = "run-abc123"
  end

  def test_initialize_with_connection_and_run_id
    service = Exa::Services::AgentRunCancel.new(@connection, run_id: @run_id)

    assert_instance_of Exa::Services::AgentRunCancel, service
  end

  def test_call_posts_to_cancel_endpoint
    stub_request(:post, "https://api.exa.ai/agent/runs/#{@run_id}/cancel")
      .to_return(
        status: 200,
        body: {
          id: @run_id,
          object: "agent_run",
          status: "cancelled"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCancel.new(@connection, run_id: @run_id)
    service.call

    assert_requested :post, "https://api.exa.ai/agent/runs/#{@run_id}/cancel"
  end

  def test_call_returns_agent_run_object
    stub_request(:post, "https://api.exa.ai/agent/runs/#{@run_id}/cancel")
      .to_return(
        status: 200,
        body: {
          id: @run_id,
          object: "agent_run",
          status: "cancelled",
          stopReason: "cancelled_by_user",
          createdAt: "2024-01-15T10:00:00Z",
          completedAt: "2024-01-15T10:01:00Z"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCancel.new(@connection, run_id: @run_id)
    result = service.call

    assert_instance_of Exa::Resources::AgentRun, result
    assert_equal @run_id, result.id
    assert_equal "agent_run", result.object
    assert_equal "cancelled", result.status
    assert result.cancelled?
    assert_equal "cancelled_by_user", result.stop_reason
    refute_nil result.completed_at
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:post, "https://api.exa.ai/agent/runs/#{@run_id}/cancel")
      .to_return(
        status: 401,
        body: { error: "Unauthorized" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCancel.new(@connection, run_id: @run_id)

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end
end
