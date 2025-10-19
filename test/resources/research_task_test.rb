require "test_helper"

class ResearchTaskTest < Minitest::Test
  def test_initialize_pending_status_with_minimal_fields
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_123",
      created_at: "2025-01-15T10:00:00Z",
      status: "pending",
      instructions: "Research Ruby programming patterns"
    )

    assert_equal "research_123", task.research_id
    assert_equal "2025-01-15T10:00:00Z", task.created_at
    assert_equal "pending", task.status
    assert_equal "Research Ruby programming patterns", task.instructions
  end

  def test_initialize_running_status_with_events
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_456",
      created_at: "2025-01-15T10:00:00Z",
      status: "running",
      instructions: "Research AI trends",
      events: []
    )

    assert_equal "research_456", task.research_id
    assert_equal "running", task.status
    assert_equal [], task.events
  end

  def test_initialize_completed_status_with_output
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_789",
      created_at: "2025-01-15T10:00:00Z",
      status: "completed",
      instructions: "Research machine learning",
      output: { results: "ML findings" },
      cost_dollars: { total: 0.05 },
      finished_at: "2025-01-15T10:30:00Z"
    )

    assert_equal "research_789", task.research_id
    assert_equal "completed", task.status
    assert_equal({ results: "ML findings" }, task.output)
    assert_equal({ total: 0.05 }, task.cost_dollars)
    assert_equal "2025-01-15T10:30:00Z", task.finished_at
  end

  def test_initialize_failed_status_with_error
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_fail",
      created_at: "2025-01-15T10:00:00Z",
      status: "failed",
      instructions: "Failed research",
      error: "API timeout error"
    )

    assert_equal "failed", task.status
    assert_equal "API timeout error", task.error
  end

  def test_initialize_canceled_status
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_cancel",
      created_at: "2025-01-15T10:00:00Z",
      status: "canceled",
      instructions: "Canceled research",
      finished_at: "2025-01-15T10:15:00Z"
    )

    assert_equal "canceled", task.status
    assert_equal "2025-01-15T10:15:00Z", task.finished_at
  end

  def test_immutability
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_123",
      created_at: "2025-01-15T10:00:00Z",
      status: "pending",
      instructions: "Test immutability"
    )

    assert_raises(FrozenError) do
      task.status = "running"
    end
  end

  def test_pending_predicate
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_123",
      created_at: "2025-01-15T10:00:00Z",
      status: "pending",
      instructions: "Test pending"
    )

    assert task.pending?
    refute task.running?
    refute task.completed?
    refute task.failed?
    refute task.canceled?
  end

  def test_running_predicate
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_123",
      created_at: "2025-01-15T10:00:00Z",
      status: "running",
      instructions: "Test running"
    )

    assert task.running?
    refute task.pending?
    refute task.completed?
    refute task.failed?
    refute task.canceled?
  end

  def test_completed_predicate
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_123",
      created_at: "2025-01-15T10:00:00Z",
      status: "completed",
      instructions: "Test completed"
    )

    assert task.completed?
    refute task.pending?
    refute task.running?
    refute task.failed?
    refute task.canceled?
  end

  def test_failed_predicate
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_123",
      created_at: "2025-01-15T10:00:00Z",
      status: "failed",
      instructions: "Test failed"
    )

    assert task.failed?
    refute task.pending?
    refute task.running?
    refute task.completed?
    refute task.canceled?
  end

  def test_canceled_predicate
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_123",
      created_at: "2025-01-15T10:00:00Z",
      status: "canceled",
      instructions: "Test canceled"
    )

    assert task.canceled?
    refute task.pending?
    refute task.running?
    refute task.completed?
    refute task.failed?
  end

  def test_finished_predicate_returns_true_for_completed
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_123",
      created_at: "2025-01-15T10:00:00Z",
      status: "completed",
      instructions: "Test finished"
    )

    assert task.finished?
  end

  def test_finished_predicate_returns_true_for_failed
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_123",
      created_at: "2025-01-15T10:00:00Z",
      status: "failed",
      instructions: "Test finished"
    )

    assert task.finished?
  end

  def test_finished_predicate_returns_false_for_pending
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_123",
      created_at: "2025-01-15T10:00:00Z",
      status: "pending",
      instructions: "Test not finished"
    )

    refute task.finished?
  end

  def test_finished_predicate_returns_false_for_running
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_123",
      created_at: "2025-01-15T10:00:00Z",
      status: "running",
      instructions: "Test not finished"
    )

    refute task.finished?
  end

  def test_to_h_for_pending_status
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_123",
      created_at: "2025-01-15T10:00:00Z",
      status: "pending",
      instructions: "Test to_h",
      model: "gpt-4"
    )

    result = task.to_h

    assert_equal "research_123", result[:research_id]
    assert_equal "2025-01-15T10:00:00Z", result[:created_at]
    assert_equal "pending", result[:status]
    assert_equal "Test to_h", result[:instructions]
    assert_equal "gpt-4", result[:model]
    refute result.key?(:output_schema)
    refute result.key?(:events)
    refute result.key?(:output)
    refute result.key?(:cost_dollars)
    refute result.key?(:finished_at)
    refute result.key?(:error)
  end

  def test_to_h_for_completed_status
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_789",
      created_at: "2025-01-15T10:00:00Z",
      status: "completed",
      instructions: "Complete test",
      model: "gpt-4",
      output_schema: { type: "object" },
      events: [{ event: "started" }],
      output: { results: "findings" },
      cost_dollars: { total: 0.10 },
      finished_at: "2025-01-15T10:30:00Z"
    )

    result = task.to_h

    assert_equal "research_789", result[:research_id]
    assert_equal "completed", result[:status]
    assert_equal "gpt-4", result[:model]
    assert_equal({ type: "object" }, result[:output_schema])
    assert_equal [{ event: "started" }], result[:events]
    assert_equal({ results: "findings" }, result[:output])
    assert_equal({ total: 0.10 }, result[:cost_dollars])
    assert_equal "2025-01-15T10:30:00Z", result[:finished_at]
    refute result.key?(:error)
  end

  def test_to_h_for_running_status
    task = Exa::Resources::ResearchTask.new(
      research_id: "research_456",
      created_at: "2025-01-15T10:00:00Z",
      status: "running",
      instructions: "Running test",
      events: [{ event: "processing" }]
    )

    result = task.to_h

    assert_equal "running", result[:status]
    assert_equal [{ event: "processing" }], result[:events]
    refute result.key?(:output)
    refute result.key?(:finished_at)
  end
end
