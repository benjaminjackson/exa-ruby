# frozen_string_literal: true

require "test_helper"

# Exercises the agent-run-create executable's argument handling without hitting
# the API: --help content (the documented Connect providers) and the
# --output-schema parse-error path, which exits before any network call.
class AgentRunCreateExeTest < Minitest::Test
  EXE = File.expand_path("../../exe/exa-ai-agent-run-create", __dir__)
  LIB = File.expand_path("../../lib", __dir__)

  CONNECT_PROVIDERS = %w[
    fiber similarweb baselayer polymarket macrobond affiliate particle financial_datasets jinko
  ].freeze

  AGENT_RUNS_URL = "https://api.exa.ai/agent/runs"

  def run_exe(*args)
    quoted = args.map { |a| "'#{a}'" }.join(" ")
    `ruby -I#{LIB} #{EXE} #{quoted} 2>&1`
  end

  # Runs the executable inside this process, so WebMock stubs apply to its
  # request. ARGV is restored afterwards; returns [stdout, stderr].
  def run_exe_in_process(*args)
    original_argv = ARGV.dup
    ARGV.replace(args)
    capture_io { load EXE }
  ensure
    ARGV.replace(original_argv)
  end

  def stub_agent_run_create
    stub_request(:post, AGENT_RUNS_URL).to_return(
      status: 200,
      body: { id: "run_123", object: "agent_run", status: "queued" }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def request_body
    body = nil
    assert_requested(:post, AGENT_RUNS_URL) { |request| body = JSON.parse(request.body) }
    body
  end

  def test_help_lists_every_connect_provider
    out = run_exe("--help")
    CONNECT_PROVIDERS.each do |slug|
      assert_includes out, slug, "--help should document the #{slug} data source"
    end
  end

  def test_help_documents_connect_flags
    out = run_exe("--help")
    assert_includes out, "--data-sources"
    assert_includes out, "--output-schema"
  end

  def test_invalid_output_schema_exits_nonzero
    out = run_exe("--query", "AI infrastructure startups", "--output-schema", "{not json")
    assert_includes out, "not valid JSON"
    refute_equal 0, $?.exitstatus
  end

  def test_help_documents_input_and_previous_run_flags
    out = run_exe("--help")
    assert_includes out, "--input-data"
    assert_includes out, "--input-exclusion"
    assert_includes out, "--previous-run-id"
  end

  def test_invalid_input_data_json_exits_nonzero
    out = run_exe("--query", "AI infrastructure startups", "--input-data", "{not json")
    assert_includes out, "not valid JSON"
    refute_equal 0, $?.exitstatus
  end

  def test_help_documents_budget_metadata_and_user_flags
    out = run_exe("--help")
    assert_includes out, "--max-cost-dollars"
    assert_includes out, "--max-duration-seconds"
    assert_includes out, "--metadata"
    assert_includes out, "--user-identifier"
  end

  def test_help_effort_list_includes_ultra
    effort_line = run_exe("--help").lines.find { |line| line.include?("--effort") }
    assert_includes effort_line, "ultra"
  end

  def test_budget_flags_send_budget_in_request_body
    stub_agent_run_create

    run_exe_in_process("--query", "Series A climate tech startups in Europe", "--api-key", "test_key",
                       "--max-cost-dollars", "5", "--max-duration-seconds", "1800")

    assert_equal({ "maxCostDollars" => 5.0, "maxDurationSeconds" => 1800 }, request_body["budget"])
  end

  def test_one_budget_flag_sends_only_that_budget_field
    stub_agent_run_create

    run_exe_in_process("--query", "Series A climate tech startups in Europe", "--api-key", "test_key",
                       "--max-cost-dollars", "2.5")

    assert_equal({ "maxCostDollars" => 2.5 }, request_body["budget"])
  end

  def test_no_budget_flags_send_no_budget
    stub_agent_run_create

    run_exe_in_process("--query", "Series A climate tech startups in Europe", "--api-key", "test_key")

    refute request_body.key?("budget")
  end

  def test_metadata_and_user_identifier_go_in_request_body
    stub_agent_run_create

    run_exe_in_process("--query", "Series A climate tech startups in Europe", "--api-key", "test_key",
                       "--metadata", '{"crm_account_id":"acct_42"}', "--user-identifier", "user_7f3a")

    body = request_body
    assert_equal({ "crm_account_id" => "acct_42" }, body["metadata"])
    assert_equal "user_7f3a", body["userIdentifier"]
  end

  def test_invalid_max_cost_dollars_exits_nonzero
    out = run_exe("--query", "AI infrastructure startups", "--max-cost-dollars", "five")
    assert_includes out, "--max-cost-dollars"
    assert_equal 1, $?.exitstatus
  end

  def test_invalid_max_duration_seconds_exits_nonzero
    out = run_exe("--query", "AI infrastructure startups", "--max-duration-seconds", "30.5")
    assert_includes out, "--max-duration-seconds"
    assert_equal 1, $?.exitstatus
  end

  def test_metadata_that_is_not_an_object_exits_nonzero
    out = run_exe("--query", "AI infrastructure startups", "--metadata", '["acct_42"]')
    assert_includes out, "--metadata"
    assert_equal 1, $?.exitstatus
  end
end
