# frozen_string_literal: true

require "test_helper"

class Exa::CLI::PollingTest < Minitest::Test
  def test_polls_until_condition_met
    call_count = 0
    result = Exa::CLI::Polling.poll(max_duration: 10) do
      call_count += 1
      if call_count >= 3
        { done: true, result: "success", status: "Done" }
      else
        { done: false, result: nil, status: "In progress" }
      end
    end

    assert_equal "success", result
    assert_equal 3, call_count
  end

  def test_uses_exponential_backoff
    start_time = Time.now
    call_times = []

    Exa::CLI::Polling.poll(
      max_duration: 10,
      initial_delay: 0.05,
      max_delay: 0.5
    ) do
      call_times << Time.now
      { done: call_times.length >= 4, result: "done", status: "OK" }
    end

    # Verify we have at least 3 delays between calls
    delays = []
    (1...call_times.length).each do |i|
      delays << (call_times[i] - call_times[i - 1])
    end

    # First delay should be ~50ms
    assert delays[0] > 0.04, "First delay should be > 0.04s"
    assert delays[0] < 0.1, "First delay should be < 0.1s"

    # Delays should increase (exponential backoff)
    if delays.length >= 2
      assert delays[1] > delays[0], "Second delay should be > first delay"
    end
  end

  def test_times_out_after_max_duration
    error = assert_raises(Exa::CLI::Polling::TimeoutError) do
      Exa::CLI::Polling.poll(max_duration: 0.05, initial_delay: 0.01) do
        { done: false, result: nil, status: "Still going..." }
      end
    end

    assert_includes error.message.downcase, "timed out"
  end

  def test_yields_status_to_block_for_progress_display
    statuses = []

    Exa::CLI::Polling.poll(max_duration: 5, initial_delay: 0.01) do
      statuses << { done: statuses.length >= 2, result: "ok", status: "Step #{statuses.length}" }
      statuses.last
    end

    assert statuses.length >= 2
    assert_equal "Step 0", statuses[0][:status]
    assert_equal "Step 1", statuses[1][:status]
  end

  def test_returns_final_result
    expected_data = { task_id: "123", output: "result" }

    result = Exa::CLI::Polling.poll(max_duration: 5, initial_delay: 0.01) do
      { done: true, result: expected_data, status: "Complete" }
    end

    assert_equal expected_data, result
  end

  def test_respects_max_delay_limit
    call_times = []

    Exa::CLI::Polling.poll(
      max_duration: 2,
      initial_delay: 0.02,
      max_delay: 0.1
    ) do
      call_times << Time.now
      { done: call_times.length >= 5, result: "done", status: "OK" }
    end

    # Check that delays don't exceed max_delay
    (1...call_times.length).each do |i|
      delay = call_times[i] - call_times[i - 1]
      # Allow some tolerance
      assert delay <= 0.15, "Delay #{delay} should not exceed max_delay of 0.1s (with tolerance)"
    end
  end
end
