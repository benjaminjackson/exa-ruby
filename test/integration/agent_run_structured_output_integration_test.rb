# frozen_string_literal: true

require "test_helper"

# Verifies the structured-output round-trip: requesting an output_schema yields
# a completed run whose output.structured is a populated object (not nil).
# The request side (output_schema -> outputSchema) is covered by the
# AgentRunCreate unit test; this exercises the response side end-to-end.
class AgentRunStructuredOutputIntegrationTest < Minitest::Test
  def setup
    skip_unless_integration_enabled
  end

  def test_completed_run_surfaces_structured_output
    VCR.use_cassette("agent_run_get_structured") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.agent_run_get("run_01struct23def456ghi789jkl")

      assert_instance_of Exa::Resources::AgentRun, result
      assert_equal "completed", result.status
      assert_equal "schema_satisfied", result.stop_reason

      structured = result.output["structured"]
      assert_instance_of Hash, structured
      assert_equal "Tokyo", structured["capital"]
      assert_in_delta 36.954, structured["population_millions"], 0.001
    end
  end
end
