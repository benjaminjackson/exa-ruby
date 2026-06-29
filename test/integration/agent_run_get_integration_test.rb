# frozen_string_literal: true

require "test_helper"

class AgentRunGetIntegrationTest < Minitest::Test
  VALID_STATUSES = %w[queued running completed failed cancelled].freeze

  def setup
    skip_unless_integration_enabled
  end

  def test_agent_run_get_returns_agent_run
    VCR.use_cassette("agent_run_get_completed") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.agent_run_get("run_01abc123def456ghi789jkl")

      assert_instance_of Exa::Resources::AgentRun, result
      assert_respond_to result, :id
      assert_respond_to result, :status
      assert_includes VALID_STATUSES, result.status
      assert_respond_to result, :output
    end
  end
end
