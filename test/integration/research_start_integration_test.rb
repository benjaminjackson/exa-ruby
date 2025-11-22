require "test_helper"

class ResearchStartIntegrationTest < Minitest::Test
  def test_research_start_creates_task
    VCR.use_cassette("research_start_ant_species") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.research_start(
        instructions: "What species of ant are similar to honeypot ants?",
        model: "exa-research"
      )

      assert_instance_of Exa::Resources::ResearchTask, result
      refute_nil result.research_id
      # Task may be "pending" or "running" depending on when API processes it
      assert_includes ["pending", "running"], result.status
    end
  end

  def test_research_task_has_expected_structure
    VCR.use_cassette("research_start_ant_species_minimal") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.research_start(
        instructions: "What species of ant are similar to honeypot ants?"
      )

      assert_respond_to result, :research_id
      assert_respond_to result, :created_at
      assert_respond_to result, :status
      assert_respond_to result, :instructions
      assert_respond_to result, :model
    end
  end
end
