# frozen_string_literal: true

require "test_helper"

class AgentRunDeleteIntegrationTest < Minitest::Test
  def setup
    skip_unless_integration_enabled
  end

  def test_agent_run_delete_returns_agent_run
    VCR.use_cassette("agent_run_delete") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.agent_run_delete("run_01abc123def456ghi789jkl")

      assert_instance_of Exa::Resources::AgentRun, result
      assert_equal "run_01abc123def456ghi789jkl", result.id
    end
  end
end
