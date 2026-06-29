# frozen_string_literal: true

require "test_helper"

# Exercises the agent-run-create executable's argument handling without hitting
# the API: --help content (the documented Connect providers) and the
# --output-schema parse-error path, which exits before any network call.
class AgentRunCreateExeTest < Minitest::Test
  EXE = File.expand_path("../../exe/exa-ai-agent-run-create", __dir__)
  LIB = File.expand_path("../../lib", __dir__)

  CONNECT_PROVIDERS = %w[
    fiber_ai similarweb baselayer affiliate particle_news financial_datasets jinko
  ].freeze

  def run_exe(*args)
    quoted = args.map { |a| "'#{a}'" }.join(" ")
    `ruby -I#{LIB} #{EXE} #{quoted} 2>&1`
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
end
