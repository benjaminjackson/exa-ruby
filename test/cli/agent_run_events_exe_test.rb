# frozen_string_literal: true

require "test_helper"

# Exercises the agent-run-events executable: --help in a subprocess, and the
# --limit / --cursor pass-through in this process so WebMock stubs apply.
class AgentRunEventsExeTest < Minitest::Test
  EXE = File.expand_path("../../exe/exa-ai-agent-run-events", __dir__)
  LIB = File.expand_path("../../lib", __dir__)
  EVENTS_URL = "https://api.exa.ai/agent/runs/run_123/events"

  def run_exe(*args)
    quoted = args.map { |a| "'#{a}'" }.join(" ")
    `ruby -I#{LIB} #{EXE} #{quoted} 2>&1`
  end

  def test_help_lists_limit_and_cursor
    out = run_exe("--help")
    assert_includes out, "--limit"
    assert_includes out, "--cursor"
  end

  def test_limit_and_cursor_are_sent_and_pretty_prints_next_cursor
    stub_request(:get, EVENTS_URL)
      .with(query: { limit: "2", cursor: "cur_1" })
      .to_return(
        status: 200,
        body: {
          object: "list",
          data: [{ id: "7", event: "agent_run.started", data: {} }],
          hasMore: true,
          nextCursor: "cur_2"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stdout, stderr, status = run_exe_in_process(
      "exa-ai-agent-run-events", "run_123", "--api-key", "test_key",
      "--limit", "2", "--cursor", "cur_1", "--output-format", "pretty"
    )
    assert_nil status, stderr

    assert_requested :get, EVENTS_URL, query: { limit: "2", cursor: "cur_1" }
    assert_includes stdout, "--cursor cur_2"
  end

  def test_unknown_option_is_printed_on_stderr_when_ruby_warnings_are_off
    original_verbose = $VERBOSE
    $VERBOSE = nil
    stdout, stderr, status = run_exe_in_process(
      "exa-ai-agent-run-events", "run_123", "--include-tool-calls", "--api-key", "test_key"
    )

    assert_equal 1, status
    assert_equal "Unknown option: --include-tool-calls\n", stderr
    assert_empty stdout
    assert_not_requested :any, /api\.exa\.ai/
  ensure
    $VERBOSE = original_verbose
  end

  def test_invalid_limit_exits_nonzero
    out = run_exe("run_123", "--limit", "ten")
    assert_includes out, "Error: --limit must be a number"
    assert_equal 1, $?.exitstatus
  end

  # Stubs the events URL with any query string, so a wrong query fails the
  # assertion instead of reaching the live API.
  def stub_events_page
    stub_request(:get, /\A#{Regexp.escape(EVENTS_URL)}/)
      .to_return(
        status: 200,
        body: {
          object: "list",
          data: [{ id: "7", event: "agent_run.started", data: {} }],
          hasMore: true,
          nextCursor: "cur_2"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def test_limit_reads_leading_zero_as_decimal
    stub_events_page

    _, stderr, status = run_exe_in_process(
      "exa-ai-agent-run-events", "run_123", "--api-key", "test_key",
      "--limit", "010"
    )
    assert_nil status, stderr

    assert_requested :get, EVENTS_URL, query: { limit: "10" }
  end

  def test_limit_rejects_hex
    out = run_exe("run_123", "--limit", "0x3e8")
    assert_includes out, "Error: --limit must be a number"
    assert_equal 1, $?.exitstatus
  end

  def test_text_output_prints_next_cursor
    stub_events_page

    stdout, stderr, status = run_exe_in_process(
      "exa-ai-agent-run-events", "run_123", "--api-key", "test_key",
      "--limit", "2", "--output-format", "text"
    )
    assert_nil status, stderr

    assert_includes stdout, "--cursor cur_2"
  end
end
