# frozen_string_literal: true

require "test_helper"

class AgentRunEventsIntegrationTest < Minitest::Test
  def setup
    skip_unless_integration_enabled
  end

  def test_agent_run_events_returns_paginated_event_list
    VCR.use_cassette("agent_run_events") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.agent_run_events("run_01abc123def456ghi789jkl")

      assert_instance_of Exa::Resources::AgentRunEventList, result
      assert_instance_of Array, result.data
      assert result.data.all? { |item| item.key?("event") }
      refute_nil result.respond_to?(:has_more)
    end
  end
end
