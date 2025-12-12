require "test_helper"

class ResearchGetIntegrationTest < Minitest::Test
  def setup
    skip_unless_integration_enabled
  end

  # Note: Using research_id from research_start_ant_species cassette
  def test_research_get_returns_research_task
    VCR.use_cassette("research_get_pending_task") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      # Use a real research_id from the research_start cassette
      result = client.research_get("r_01k7ywj6r2er4h7ff1cdf7y8c7")

      assert_instance_of Exa::Resources::ResearchTask, result
      assert_respond_to result, :research_id
      assert_respond_to result, :status
    end
  end

  def test_research_get_with_events_parameter
    VCR.use_cassette("research_get_with_events") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.research_get("r_01k7ywj6r2er4h7ff1cdf7y8c7", events: true)

      assert_instance_of Exa::Resources::ResearchTask, result
    end
  end

  def test_research_polling_workflow
    VCR.use_cassette("research_polling_workflow") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      # Simulate polling: start with pending, keep fetching until finished
      result = client.research_get("r_01k7ywj6r2er4h7ff1cdf7y8c7")

      assert_instance_of Exa::Resources::ResearchTask, result
      # Verify status is one of the valid states
      assert_includes ["pending", "running", "completed", "failed", "canceled"], result.status
      # Verify predicate methods work and return boolean values
      assert(result.pending?.is_a?(TrueClass) || result.pending?.is_a?(FalseClass))
      assert(result.finished?.is_a?(TrueClass) || result.finished?.is_a?(FalseClass))
    end
  end
end
