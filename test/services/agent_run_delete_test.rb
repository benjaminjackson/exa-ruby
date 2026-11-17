require "test_helper"
require_relative "../../lib/exa/services/agent_run_delete"

class AgentRunDeleteTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
    @run_id = "run-abc123"
  end

  def test_initialize_with_connection_and_run_id
    service = Exa::Services::AgentRunDelete.new(@connection, run_id: @run_id)

    assert_instance_of Exa::Services::AgentRunDelete, service
  end

  def stub_delete_response
    stub_request(:delete, "https://api.exa.ai/agent/runs/#{@run_id}")
      .to_return(
        status: 200,
        body: { id: @run_id, object: "agent_run.deleted", deleted: true }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def test_call_sends_delete_to_run_endpoint
    stub_delete_response

    Exa::Services::AgentRunDelete.new(@connection, run_id: @run_id).call

    assert_requested :delete, "https://api.exa.ai/agent/runs/#{@run_id}"
  end

  def test_call_returns_deletion_with_id_and_deleted_true
    stub_delete_response

    result = Exa::Services::AgentRunDelete.new(@connection, run_id: @run_id).call

    assert_instance_of Exa::Resources::AgentRunDeletion, result
    assert_equal @run_id, result.id
    assert_equal "agent_run.deleted", result.object
    assert_equal true, result.deleted
    assert result.deleted?
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
