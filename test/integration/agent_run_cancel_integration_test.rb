# frozen_string_literal: true

require "test_helper"

class AgentRunCancelIntegrationTest < Minitest::Test
  def setup
    skip_unless_integration_enabled
  end

  def test_agent_run_cancel_returns_cancelled_run
    VCR.use_cassette("agent_run_cancel") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.agent_run_cancel("run_01abc123def456ghi789jkl")

      assert_instance_of Exa::Resources::AgentRun, result
      assert_equal "cancelled", result.status
      assert result.cancelled?
    end
  end
end
