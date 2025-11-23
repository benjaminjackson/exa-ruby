require "test_helper"

class MonitorRunTest < Minitest::Test
  def test_initializes_with_all_required_fields
    run = Exa::Resources::MonitorRun.new(
      id: "run_123",
      object: "monitor.run",
      monitor_id: "mon_456",
      status: "completed",
      created_at: "2025-01-15T10:00:00Z",
      updated_at: "2025-01-15T10:05:00Z",
      completed_at: "2025-01-15T10:05:00Z",
      failed_at: nil,
      failed_reason: nil
    )

    assert_equal "run_123", run.id
    assert_equal "monitor.run", run.object
    assert_equal "mon_456", run.monitor_id
    assert_equal "completed", run.status
    assert_equal "2025-01-15T10:00:00Z", run.created_at
    assert_equal "2025-01-15T10:05:00Z", run.updated_at
    assert_equal "2025-01-15T10:05:00Z", run.completed_at
    assert_nil run.failed_at
    assert_nil run.failed_reason
  end

  def test_pending_returns_true_when_status_is_pending
    run = Exa::Resources::MonitorRun.new(status: "pending")
    assert run.pending?
  end

  def test_pending_returns_false_when_status_is_not_pending
    run = Exa::Resources::MonitorRun.new(status: "running")
    refute run.pending?
  end

  def test_running_returns_true_when_status_is_running
    run = Exa::Resources::MonitorRun.new(status: "running")
    assert run.running?
  end

  def test_running_returns_false_when_status_is_not_running
    run = Exa::Resources::MonitorRun.new(status: "completed")
    refute run.running?
  end

  def test_completed_returns_true_when_status_is_completed
    run = Exa::Resources::MonitorRun.new(status: "completed")
    assert run.completed?
  end

  def test_completed_returns_false_when_status_is_not_completed
    run = Exa::Resources::MonitorRun.new(status: "running")
    refute run.completed?
  end

  def test_failed_returns_true_when_status_is_failed
    run = Exa::Resources::MonitorRun.new(status: "failed")
    assert run.failed?
  end

  def test_failed_returns_false_when_status_is_not_failed
    run = Exa::Resources::MonitorRun.new(status: "completed")
    refute run.failed?
  end

  def test_to_h_returns_compact_hash_with_all_fields
    run = Exa::Resources::MonitorRun.new(
      id: "run_123",
      object: "monitor.run",
      monitor_id: "mon_456",
      status: "completed",
      created_at: "2025-01-15T10:00:00Z",
      updated_at: "2025-01-15T10:05:00Z",
      completed_at: "2025-01-15T10:05:00Z",
      failed_at: nil,
      failed_reason: nil
    )

    hash = run.to_h

    assert_equal "run_123", hash[:id]
    assert_equal "monitor.run", hash[:object]
    assert_equal "mon_456", hash[:monitor_id]
    assert_equal "completed", hash[:status]
    assert_equal "2025-01-15T10:00:00Z", hash[:created_at]
    assert_equal "2025-01-15T10:05:00Z", hash[:updated_at]
    assert_equal "2025-01-15T10:05:00Z", hash[:completed_at]
    refute_includes hash.keys, :failed_at
    refute_includes hash.keys, :failed_reason
  end
end
