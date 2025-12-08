require "test_helper"

class ResearchListIntegrationTest < Minitest::Test
  def setup
    skip_unless_integration_enabled
  end

  def test_research_list_returns_list_object
    VCR.use_cassette("research_list_first_page") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.research_list(limit: 5)

      assert_instance_of Exa::Resources::ResearchList, result
      assert_instance_of Array, result.data
    end
  end

  def test_research_list_maps_data_to_research_tasks
    VCR.use_cassette("research_list_first_page") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.research_list(limit: 5)

      unless result.data.empty?
        first_task = result.data.first
        assert_instance_of Exa::Resources::ResearchTask, first_task
        assert_respond_to first_task, :research_id
        assert_respond_to first_task, :status
      end
    end
  end

  def test_research_list_pagination_has_more_flag
    VCR.use_cassette("research_list_first_page") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.research_list(limit: 5)

      assert [TrueClass, FalseClass].include?(result.has_more.class)
    end
  end

  def test_research_list_pagination_cursor
    VCR.use_cassette("research_list_first_page") do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      result = client.research_list(limit: 5)

      if result.has_more
        assert_not_nil result.next_cursor, "Expected next_cursor when has_more is true"
      else
        # May be nil or present depending on API behavior
        assert [NilClass, String].include?(result.next_cursor.class)
      end
    end
  end
end
