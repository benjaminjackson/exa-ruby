require "test_helper"
require_relative "../../lib/exa/resources/agent_run"

class AgentRunTest < Minitest::Test
  def test_from_response_maps_camel_case_payload
    run = Exa::Resources::AgentRun.from_response(
      "id" => "r1", "status" => "completed", "stopReason" => "schema_satisfied",
      "costDollars" => { "total" => 0.01 }, "completedAt" => "t"
    )

    assert_equal "agent_run", run.object
    assert_equal "schema_satisfied", run.stop_reason
    assert_equal({ "total" => 0.01 }, run.cost_dollars)
    assert_equal "t", run.completed_at
  end

  def test_from_response_defaults_object_when_absent
    run = Exa::Resources::AgentRun.from_response("id" => "r1", "status" => "failed")

    assert_equal "agent_run", run.object
    assert run.failed?
  end

  def test_initialize_queued_status_with_minimal_fields
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "queued"
    )

    assert_equal "run_abc123", run.id
    assert_equal "agent_run", run.object
    assert_equal "queued", run.status
  end

  def test_initialize_running_status
    run = Exa::Resources::AgentRun.new(
      id: "run_def456",
      object: "agent_run",
      status: "running",
      created_at: "2025-06-01T10:00:00Z"
    )

    assert_equal "running", run.status
    assert_equal "2025-06-01T10:00:00Z", run.created_at
  end

  def test_initialize_completed_status_with_output
    run = Exa::Resources::AgentRun.new(
      id: "run_ghi789",
      object: "agent_run",
      status: "completed",
      stop_reason: "end_turn",
      created_at: "2025-06-01T10:00:00Z",
      completed_at: "2025-06-01T10:05:00Z",
      output: { text: "Analysis complete" },
      usage: { input_tokens: 500, output_tokens: 200 },
      cost_dollars: { total: 0.02 }
    )

    assert_equal "completed", run.status
    assert_equal "end_turn", run.stop_reason
    assert_equal "2025-06-01T10:05:00Z", run.completed_at
    assert_equal({ text: "Analysis complete" }, run.output)
    assert_equal({ input_tokens: 500, output_tokens: 200 }, run.usage)
    assert_equal({ total: 0.02 }, run.cost_dollars)
  end

  def test_initialize_failed_status
    run = Exa::Resources::AgentRun.new(
      id: "run_fail001",
      object: "agent_run",
      status: "failed",
      stop_reason: "error",
      created_at: "2025-06-01T10:00:00Z",
      completed_at: "2025-06-01T10:01:00Z"
    )

    assert_equal "failed", run.status
    assert_equal "error", run.stop_reason
  end

  def test_initialize_cancelled_status
    run = Exa::Resources::AgentRun.new(
      id: "run_cancel001",
      object: "agent_run",
      status: "cancelled",
      stop_reason: "user_cancelled",
      created_at: "2025-06-01T10:00:00Z",
      completed_at: "2025-06-01T10:02:00Z"
    )

    assert_equal "cancelled", run.status
    assert_equal "user_cancelled", run.stop_reason
  end

  def test_immutability
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "queued"
    )

    assert_raises(FrozenError) do
      run.status = "running"
    end
  end

  def test_queued_predicate
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "queued"
    )

    assert run.queued?
    refute run.running?
    refute run.completed?
    refute run.failed?
    refute run.cancelled?
  end

  def test_running_predicate
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "running"
    )

    assert run.running?
    refute run.queued?
    refute run.completed?
    refute run.failed?
    refute run.cancelled?
  end

  def test_completed_predicate
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "completed"
    )

    assert run.completed?
    refute run.queued?
    refute run.running?
    refute run.failed?
    refute run.cancelled?
  end

  def test_failed_predicate
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "failed"
    )

    assert run.failed?
    refute run.queued?
    refute run.running?
    refute run.completed?
    refute run.cancelled?
  end

  def test_cancelled_predicate
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "cancelled"
    )

    assert run.cancelled?
    refute run.queued?
    refute run.running?
    refute run.completed?
    refute run.failed?
  end

  def test_finished_returns_false_for_queued
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "queued"
    )

    refute run.finished?
  end

  def test_finished_returns_false_for_running
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "running"
    )

    refute run.finished?
  end

  def test_finished_returns_true_for_completed
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "completed"
    )

    assert run.finished?
  end

  def test_finished_returns_true_for_failed
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "failed"
    )

    assert run.finished?
  end

  def test_finished_returns_true_for_cancelled
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "cancelled"
    )

    assert run.finished?
  end

  def test_to_h_compacts_nils_for_queued_run
    run = Exa::Resources::AgentRun.new(
      id: "run_abc123",
      object: "agent_run",
      status: "queued"
    )

    result = run.to_h

    assert_equal "run_abc123", result[:id]
    assert_equal "agent_run", result[:object]
    assert_equal "queued", result[:status]
    refute result.key?(:stop_reason)
    refute result.key?(:created_at)
    refute result.key?(:completed_at)
    refute result.key?(:request)
    refute result.key?(:output)
    refute result.key?(:usage)
    refute result.key?(:cost_dollars)
  end

  def test_to_h_includes_all_fields_for_completed_run
    run = Exa::Resources::AgentRun.new(
      id: "run_ghi789",
      object: "agent_run",
      status: "completed",
      stop_reason: "end_turn",
      created_at: "2025-06-01T10:00:00Z",
      completed_at: "2025-06-01T10:05:00Z",
      request: { model: "claude-3-5-sonnet" },
      output: { text: "Research findings" },
      usage: { input_tokens: 1000, output_tokens: 400 },
      cost_dollars: { total: 0.04 }
    )

    result = run.to_h

    assert_equal "run_ghi789", result[:id]
    assert_equal "completed", result[:status]
    assert_equal "end_turn", result[:stop_reason]
    assert_equal "2025-06-01T10:00:00Z", result[:created_at]
    assert_equal "2025-06-01T10:05:00Z", result[:completed_at]
    assert_equal({ model: "claude-3-5-sonnet" }, result[:request])
    assert_equal({ text: "Research findings" }, result[:output])
    assert_equal({ input_tokens: 1000, output_tokens: 400 }, result[:usage])
    assert_equal({ total: 0.04 }, result[:cost_dollars])
  end
end
