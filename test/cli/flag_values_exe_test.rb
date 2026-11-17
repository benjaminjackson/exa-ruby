# frozen_string_literal: true

require "test_helper"

# Every command other than search, get-contents and find-similar (those have
# their own tests) must stop with one "Error: <flag>" line, exit 1 and send
# no request when a flag that takes a value has no value, or gets another
# flag of the same command as its value. Each test reads the flags from the
# command's --help output; every flag not in the given list takes a value.
class Exa::CLI::FlagValuesExeTest < Minitest::Test
  RUN_ID = "run_01jq8x2m4k5n6p7r8s9t0v1w2x"
  MONITOR_ID = "mon_01jq8x2m4k5n6p7r8s9t0v1w2y"

  def test_answer_checks_every_flag_value
    assert_every_value_flag_checked(
      "exa-ai-answer", ["What is the latest valuation of SpaceX?"],
      %w[--stream --text --skip-citations --no-citations --help]
    )
  end

  def test_agent_run_create_checks_every_flag_value
    assert_every_value_flag_checked(
      "exa-ai-agent-run-create", ["--query", "Find Series A AI infrastructure startups in Europe"],
      %w[--wait --help]
    )
  end

  def test_agent_run_get_cancel_delete_and_stop_check_every_flag_value
    %w[get cancel delete stop].each do |action|
      assert_every_value_flag_checked("exa-ai-agent-run-#{action}", [RUN_ID], %w[--help])
    end
  end

  def test_agent_run_events_checks_every_flag_value
    assert_every_value_flag_checked("exa-ai-agent-run-events", [RUN_ID], %w[--help])
  end

  def test_agent_run_list_checks_every_flag_value
    assert_every_value_flag_checked("exa-ai-agent-run-list", [], %w[--help])
  end

  def test_context_checks_every_flag_value
    assert_every_value_flag_checked("exa-ai-context", ["React hooks for data fetching with suspense"], %w[--help])
  end

  def test_search_monitor_batch_checks_every_flag_value
    assert_every_value_flag_checked("exa-ai-search-monitor-batch", ["--action", "pause"], %w[--execute --help])
  end

  def test_search_monitor_create_checks_every_flag_value
    assert_every_value_flag_checked(
      "exa-ai-search-monitor-create",
      ["--query", "Series A funding rounds for AI infrastructure startups", "--webhook-url", "https://hooks.example.com/exa"],
      %w[--help]
    )
  end

  def test_search_monitor_get_delete_and_trigger_check_every_flag_value
    %w[get delete trigger].each do |action|
      assert_every_value_flag_checked("exa-ai-search-monitor-#{action}", [MONITOR_ID], %w[--help])
    end
  end

  def test_search_monitor_update_checks_every_flag_value
    assert_every_value_flag_checked("exa-ai-search-monitor-update", [MONITOR_ID], %w[--remove-trigger --help])
  end

  def test_search_monitor_list_checks_every_flag_value
    assert_every_value_flag_checked("exa-ai-search-monitor-list", [], %w[--help])
  end

  def test_search_monitor_runs_list_checks_every_flag_value
    assert_every_value_flag_checked("exa-ai-search-monitor-runs-list", [MONITOR_ID], %w[--help])
  end

  def test_search_monitor_runs_get_checks_every_flag_value
    assert_every_value_flag_checked("exa-ai-search-monitor-runs-get", [MONITOR_ID, RUN_ID], %w[--help])
  end

  def test_answer_keeps_a_system_prompt_that_starts_with_dashes_and_has_whitespace
    posted_body = nil
    stub_request(:post, "https://api.exa.ai/answer")
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(status: 200, body: { answer: "About $350 billion", citations: [] }.to_json,
                 headers: { "Content-Type" => "application/json" })

    run_exe_in_process(
      "exa-ai-answer", "What is the latest valuation of SpaceX?",
      "--system-prompt", "--terse answers only", "--api-key", "test_key"
    )

    assert_equal "--terse answers only", posted_body["systemPrompt"]
  end

  private

  # Runs each value-taking flag of the command, read from its --help, once
  # with no value and once with another flag of the command as its value,
  # after base_argv and a valid --api-key. --output-format stands in as the
  # next flag, or --api-key when --output-format is the flag under test.
  def assert_every_value_flag_checked(exe_name, base_argv, flags_without_value)
    help_text, = run_exe_in_process(exe_name, "--help")
    help_flags = help_text.scan(/^\s+(--[a-z][a-z-]*)/).flatten.uniq
    assert_includes help_flags, "--api-key", exe_name

    (help_flags - flags_without_value).each do |flag|
      next_flag = flag == "--output-format" ? "--api-key" : "--output-format"
      [[], [next_flag]].each do |rest|
        case_name = [exe_name, flag, *rest].join(" ")
        stub_request(:any, /api\.exa\.ai/)
        _stdout, stderr, exit_status = run_exe_in_process(exe_name, *base_argv, "--api-key", "test_key", flag, *rest)

        assert_equal 1, exit_status, "#{case_name}: #{stderr}"
        assert_equal 1, stderr.lines.size, "#{case_name}: #{stderr}"
        assert_match(/\AError: #{Regexp.escape(flag)}(?![\w-])/, stderr, case_name)
        assert_not_requested :any, /api\.exa\.ai/
      end
    end
  end
end
