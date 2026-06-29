# frozen_string_literal: true

require "test_helper"

class AgentRunStreamIntegrationTest < Minitest::Test
  def setup
    skip_unless_integration_enabled
  end

  def test_agent_run_stream_yields_event_type_and_data_pairs
    VCR.use_cassette("agent_run_stream") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      events = []

      client.agent_run_stream(query: "AI infrastructure startups that raised Series A in 2025") do |event_type, data|
        events << [event_type, data]
      end

      refute_empty events
      assert events.all? { |event_type, _data| event_type.is_a?(String) }
      assert events.all? { |_event_type, data| data.is_a?(Hash) }
      assert events.any? { |event_type, _data| event_type == "agent_run.completed" }
    end
  end
end
