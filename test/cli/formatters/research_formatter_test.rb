require "test_helper"

class ResearchFormatterTest < Minitest::Test
  def setup
    @pending_task = Exa::Resources::ResearchTask.new(
      research_id: "research_123",
      status: "pending",
      created_at: "2025-01-15T10:00:00Z",
      instructions: "Research Ruby programming best practices",
      finished_at: nil,
      output: nil,
      error: nil,
      cost_dollars: nil,
      events: nil
    )

    @running_task = Exa::Resources::ResearchTask.new(
      research_id: "research_456",
      status: "running",
      created_at: "2025-01-15T10:05:00Z",
      instructions: "Research Python vs Ruby performance",
      finished_at: nil,
      output: nil,
      error: nil,
      cost_dollars: nil,
      events: nil
    )

    @completed_task = Exa::Resources::ResearchTask.new(
      research_id: "research_789",
      status: "completed",
      created_at: "2025-01-15T10:10:00Z",
      instructions: "Research modern web frameworks",
      finished_at: "2025-01-15T10:15:00Z",
      output: "Research findings about Ruby programming...",
      error: nil,
      cost_dollars: 0.05,
      events: nil
    )

    @failed_task = Exa::Resources::ResearchTask.new(
      research_id: "research_fail",
      status: "failed",
      created_at: "2025-01-15T10:20:00Z",
      instructions: "Research AI trends",
      finished_at: "2025-01-15T10:21:00Z",
      output: nil,
      error: "API rate limit exceeded",
      cost_dollars: nil,
      events: nil
    )

    @canceled_task = Exa::Resources::ResearchTask.new(
      research_id: "research_cancel",
      status: "canceled",
      created_at: "2025-01-15T10:25:00Z",
      instructions: "Research database systems",
      finished_at: "2025-01-15T10:26:00Z",
      output: nil,
      error: nil,
      cost_dollars: nil,
      events: nil
    )

    @task_with_events = Exa::Resources::ResearchTask.new(
      research_id: "research_events",
      status: "completed",
      created_at: "2025-01-15T10:30:00Z",
      instructions: "Research cloud platforms",
      finished_at: "2025-01-15T10:35:00Z",
      output: "Final output",
      error: nil,
      cost_dollars: 0.10,
      events: [
        "Task started",
        "Searching for sources...",
        "Found 10 sources",
        "Analyzing content...",
        "Generating output...",
        "Task completed"
      ]
    )
  end

  def test_json_format_returns_json_string
    result = Exa::CLI::Formatters::ResearchFormatter.format_task(@pending_task, "json")

    assert_kind_of String, result
    parsed = JSON.parse(result)
    assert_equal "research_123", parsed["research_id"]
    assert_equal "pending", parsed["status"]
  end

  def test_pretty_format_for_pending_status
    result = Exa::CLI::Formatters::ResearchFormatter.format_task(@pending_task, "pretty")

    assert_includes result, "Research Task: research_123"
    assert_includes result, "Status: PENDING"
    assert_includes result, "Created: 2025-01-15T10:00:00Z"
    assert_includes result, "Task is pending execution..."
  end

  def test_pretty_format_for_running_status
    result = Exa::CLI::Formatters::ResearchFormatter.format_task(@running_task, "pretty")

    assert_includes result, "Research Task: research_456"
    assert_includes result, "Status: RUNNING"
    assert_includes result, "Task is running..."
  end

  def test_pretty_format_for_completed_status_shows_output
    result = Exa::CLI::Formatters::ResearchFormatter.format_task(@completed_task, "pretty")

    assert_includes result, "Research Task: research_789"
    assert_includes result, "Status: COMPLETED"
    assert_includes result, "Output:"
    assert_includes result, "Research findings about Ruby programming..."
    assert_includes result, "Cost: $0.05"
  end

  def test_pretty_format_for_failed_status_shows_error
    result = Exa::CLI::Formatters::ResearchFormatter.format_task(@failed_task, "pretty")

    assert_includes result, "Research Task: research_fail"
    assert_includes result, "Status: FAILED"
    assert_includes result, "Error: API rate limit exceeded"
  end

  def test_pretty_format_for_canceled_status
    result = Exa::CLI::Formatters::ResearchFormatter.format_task(@canceled_task, "pretty")

    assert_includes result, "Research Task: research_cancel"
    assert_includes result, "Status: CANCELED"
    assert_includes result, "Task was canceled"
    assert_includes result, "Finished: 2025-01-15T10:26:00Z"
  end

  def test_pretty_format_includes_events_when_present
    result = Exa::CLI::Formatters::ResearchFormatter.format_task(@task_with_events, "pretty", show_events: true)

    assert_includes result, "Events:"
    assert_includes result, "- Task started"
    assert_includes result, "- Searching for sources..."
    assert_includes result, "- Found 10 sources"
    assert_includes result, "- Task completed"
  end

  def test_pretty_format_excludes_events_when_flag_false
    result = Exa::CLI::Formatters::ResearchFormatter.format_task(@task_with_events, "pretty", show_events: false)

    refute_includes result, "Events:"
    refute_includes result, "- Task started"
  end

  def test_list_format_shows_table_of_tasks
    list = Exa::Resources::ResearchList.new(
      data: [@pending_task, @running_task, @completed_task],
      has_more: false,
      next_cursor: nil
    )

    result = Exa::CLI::Formatters::ResearchFormatter.format_list(list, "pretty")

    assert_includes result, "Research Tasks (3):"
    assert_includes result, "Task ID"
    assert_includes result, "Status"
    assert_includes result, "Created"
    assert_includes result, "research_123"
    assert_includes result, "research_456"
    assert_includes result, "research_789"
    assert_includes result, "PENDING"
    assert_includes result, "RUNNING"
    assert_includes result, "COMPLETED"
    assert_includes result, "End of results."
  end

  def test_list_format_shows_pagination_info_when_has_more
    list = Exa::Resources::ResearchList.new(
      data: [@pending_task, @running_task],
      has_more: true,
      next_cursor: "cursor_next_123"
    )

    result = Exa::CLI::Formatters::ResearchFormatter.format_list(list, "pretty")

    assert_includes result, "More results available."
    assert_includes result, "Use --cursor cursor_next_123 for next page."
  end

  def test_list_format_shows_empty_message_when_no_tasks
    list = Exa::Resources::ResearchList.new(
      data: [],
      has_more: false,
      next_cursor: nil
    )

    result = Exa::CLI::Formatters::ResearchFormatter.format_list(list, "pretty")

    assert_includes result, "Research Tasks (0):"
    assert_includes result, "No tasks found."
  end

  def test_list_json_format_returns_json_string
    list = Exa::Resources::ResearchList.new(
      data: [@pending_task, @running_task],
      has_more: false,
      next_cursor: nil
    )

    result = Exa::CLI::Formatters::ResearchFormatter.format_list(list, "json")

    assert_kind_of String, result
    parsed = JSON.parse(result)
    assert_equal 2, parsed["data"].length
    assert_equal false, parsed["has_more"]
  end

  def test_text_format_for_completed_status
    result = Exa::CLI::Formatters::ResearchFormatter.format_task(@completed_task, "text")

    assert_includes result, "research_789"
    assert_includes result, "COMPLETED"
    assert_includes result, "2025-01-15T10:10:00Z"
    assert_includes result, "Research findings about Ruby programming..."
  end

  def test_text_format_for_failed_status
    result = Exa::CLI::Formatters::ResearchFormatter.format_task(@failed_task, "text")

    assert_includes result, "research_fail"
    assert_includes result, "FAILED"
    assert_includes result, "Error: API rate limit exceeded"
  end

  def test_list_text_format_shows_task_ids
    list = Exa::Resources::ResearchList.new(
      data: [@pending_task, @running_task, @completed_task],
      has_more: false,
      next_cursor: nil
    )

    result = Exa::CLI::Formatters::ResearchFormatter.format_list(list, "text")

    lines = result.split("\n")
    assert_equal 3, lines.length
    assert_includes result, "research_123"
    assert_includes result, "PENDING"
    assert_includes result, "research_456"
    assert_includes result, "RUNNING"
    assert_includes result, "research_789"
    assert_includes result, "COMPLETED"
  end
end
