# frozen_string_literal: true

require "test_helper"

class AgentRunListIntegrationTest < Minitest::Test
  def setup
    skip_unless_integration_enabled
  end

  def test_agent_run_list_returns_agent_run_list
    VCR.use_cassette("agent_run_list_first_page") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.agent_run_list(limit: 5)

      assert_instance_of Exa::Resources::AgentRunList, result
      assert_instance_of Array, result.data
    end
  end

  def test_agent_run_list_data_items_are_agent_runs
    VCR.use_cassette("agent_run_list_first_page") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.agent_run_list(limit: 5)

      unless result.data.empty?
        assert_instance_of Exa::Resources::AgentRun, result.data.first
      end
    end
  end

  def test_agent_run_list_has_pagination_fields
    VCR.use_cassette("agent_run_list_first_page") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.agent_run_list(limit: 5)

      assert(result.has_more == true || result.has_more == false, "has_more should be a boolean")
      assert(result.next_cursor.nil? || result.next_cursor.is_a?(String), "next_cursor should be String or nil")
    end
  end
end
