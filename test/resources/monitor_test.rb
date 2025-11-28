require "test_helper"

class MonitorTest < Minitest::Test
  def test_initializes_with_all_required_fields
    monitor = Exa::Resources::Monitor.new(
      id: "mon_123",
      object: "monitor",
      status: "active",
      webset_id: "ws_456",
      cadence: { cron: "0 0 * * *", timezone: "America/New_York" },
      behavior: { type: "search", query: "AI startups", count: 10 },
      created_at: "2025-01-15T10:00:00Z",
      updated_at: "2025-01-15T10:00:00Z"
    )

    assert_equal "mon_123", monitor.id
    assert_equal "monitor", monitor.object
    assert_equal "active", monitor.status
    assert_equal "ws_456", monitor.webset_id
    assert_equal({ cron: "0 0 * * *", timezone: "America/New_York" }, monitor.cadence)
    assert_equal({ type: "search", query: "AI startups", count: 10 }, monitor.behavior)
    assert_equal "2025-01-15T10:00:00Z", monitor.created_at
    assert_equal "2025-01-15T10:00:00Z", monitor.updated_at
  end

  def test_pending_returns_true_when_status_is_pending
    monitor = Exa::Resources::Monitor.new(status: "pending")
    assert monitor.pending?
  end

  def test_pending_returns_false_when_status_is_not_pending
    monitor = Exa::Resources::Monitor.new(status: "active")
    refute monitor.pending?
  end

  def test_active_returns_true_when_status_is_active
    monitor = Exa::Resources::Monitor.new(status: "active")
    assert monitor.active?
  end

  def test_active_returns_false_when_status_is_not_active
    monitor = Exa::Resources::Monitor.new(status: "pending")
    refute monitor.active?
  end

  def test_paused_returns_true_when_status_is_paused
    monitor = Exa::Resources::Monitor.new(status: "paused")
    assert monitor.paused?
  end

  def test_paused_returns_false_when_status_is_not_paused
    monitor = Exa::Resources::Monitor.new(status: "active")
    refute monitor.paused?
  end

  def test_to_h_returns_compact_hash_with_all_fields
    monitor = Exa::Resources::Monitor.new(
      id: "mon_123",
      object: "monitor",
      status: "active",
      webset_id: "ws_456",
      cadence: { cron: "0 0 * * *", timezone: "America/New_York" },
      behavior: { type: "search", query: "AI startups", count: 10 },
      created_at: "2025-01-15T10:00:00Z",
      updated_at: "2025-01-15T10:00:00Z"
    )

    hash = monitor.to_h

    assert_equal "mon_123", hash[:id]
    assert_equal "monitor", hash[:object]
    assert_equal "active", hash[:status]
    assert_equal "ws_456", hash[:webset_id]
    assert_equal({ cron: "0 0 * * *", timezone: "America/New_York" }, hash[:cadence])
    assert_equal({ type: "search", query: "AI startups", count: 10 }, hash[:behavior])
    assert_equal "2025-01-15T10:00:00Z", hash[:created_at]
    assert_equal "2025-01-15T10:00:00Z", hash[:updated_at]
  end
end
