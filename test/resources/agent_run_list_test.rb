require "test_helper"
require_relative "../../lib/exa/resources/agent_run"
require_relative "../../lib/exa/resources/agent_run_list"

class AgentRunListTest < Minitest::Test
  def test_initialize_with_data_has_more_and_next_cursor
    list = Exa::Resources::AgentRunList.new(
      data: [],
      has_more: false,
      next_cursor: nil
    )

    assert_equal [], list.data
    assert_equal false, list.has_more
    assert_nil list.next_cursor
  end

  def test_initialize_with_next_cursor_for_pagination
    list = Exa::Resources::AgentRunList.new(
      data: [],
      has_more: true,
      next_cursor: "cursor_abc123"
    )

    assert_equal "cursor_abc123", list.next_cursor
  end

  def test_immutability
    list = Exa::Resources::AgentRunList.new(
      data: [],
      has_more: false,
      next_cursor: nil
    )

    assert_raises(FrozenError) do
      list.data = []
    end
  end

  def test_to_h_returns_correct_hash
    data = [{ id: "run_abc123" }]
    list = Exa::Resources::AgentRunList.new(
      data: data,
      has_more: true,
      next_cursor: "cursor_def456"
    )

    expected = {
      data: data,
      has_more: true,
      next_cursor: "cursor_def456"
    }

    assert_equal expected, list.to_h
  end

  def test_to_h_maps_agent_run_items_via_to_h
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "completed",
      stop_reason: "end_turn"
    )
    list = Exa::Resources::AgentRunList.new(
      data: [run],
      has_more: false
    )

    result = list.to_h

    assert_equal 1, result[:data].length
    assert_equal "run_abc123", result[:data].first[:id]
    assert_equal "completed", result[:data].first[:status]
  end
end
