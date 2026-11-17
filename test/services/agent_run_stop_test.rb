require "test_helper"
require_relative "../../lib/exa/services/agent_run_stop"
require_relative "../../lib/exa/resources/agent_run"

class AgentRunStopTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
    @run_id = "run-abc123"
    @stop_url = "https://api.exa.ai/agent/runs/#{@run_id}/stop"
  end

  def test_call_posts_to_stop_endpoint_and_returns_completed_run
    stub_request(:post, @stop_url)
      .to_return(
        status: 200,
        body: {
          id: @run_id,
          object: "agent_run",
          status: "completed",
          stopReason: "stopped",
          output: { text: "Partial findings on lithium battery recycling startups" }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = Exa::Services::AgentRunStop.new(@connection, run_id: @run_id).call

    assert_requested :post, @stop_url
    assert_instance_of Exa::Resources::AgentRun, result
    assert_equal "completed", result.status
    assert_equal "stopped", result.stop_reason
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:post, @stop_url)
      .to_return(
        status: 401,
        body: { error: "Unauthorized" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunStop.new(@connection, run_id: @run_id)

    assert_raises(Exa::Unauthorized) { service.call }
  end
end
