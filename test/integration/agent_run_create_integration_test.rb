# frozen_string_literal: true

require "test_helper"

class AgentRunCreateIntegrationTest < Minitest::Test
  def setup
    skip_unless_integration_enabled
  end

  def test_agent_run_create_returns_agent_run
    VCR.use_cassette("agent_run_create") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.agent_run_create(query: "AI infrastructure startups that raised Series A in 2025")

      assert_instance_of Exa::Resources::AgentRun, result
      assert result.id, "expected result to have an id"
      assert_includes ["queued", "running"], result.status
      assert_respond_to result, :created_at
      assert_respond_to result, :request
    end
  end
end
