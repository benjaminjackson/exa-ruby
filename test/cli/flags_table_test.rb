# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "exa/cli/search_parser"
require "exa/cli/get_contents"

# Tests for the public flag tables of exa-ai search and exa-ai get-contents
# (Exa::CLI::SearchParser::FLAGS and Exa::CLI::GetContents::FLAGS) and for
# the --flags-json option that prints them.
class Exa::CLI::FlagsTableTest < Minitest::Test
  ENTRY_KEYS = %i[flag api_field deprecated replacement reason].freeze

  # A sample value for each table flag that takes one. Flags not listed here
  # take no value.
  SAMPLE_VALUES = {
    "--num-results" => "5", "--type" => "auto", "--category" => "company",
    "--include-domains" => "arxiv.org", "--exclude-domains" => "reddit.com",
    "--start-published-date" => "2024-01-01", "--end-published-date" => "2024-12-31",
    "--start-crawl-date" => "2024-01-01", "--end-crawl-date" => "2024-12-31",
    "--include-text" => "Series A", "--exclude-text" => "acquired",
    "--text-max-characters" => "3000", "--text-verbosity" => "compact",
    "--summary-query" => "Name the founders", "--summary-schema" => '{"type":"object"}',
    "--context-max-characters" => "500", "--subpages" => "1", "--subpage-target" => "careers",
    "--links" => "5", "--image-links" => "10", "--highlights-max-characters" => "300",
    "--highlights-num-sentences" => "2", "--highlights-per-url" => "1",
    "--highlights-query" => "funding rounds", "--highlights-verbosity" => "low",
    "--livecrawl-timeout" => "5000", "--max-age-hours" => "24",
    "--snapshot-as-of" => "2026-01-01T00:00:00Z", "--additional-queries" => "AI chip startups",
    "--output-schema" => '{"type":"object"}', "--user-location" => "US",
    "--objective" => "Find seed-stage AI infrastructure companies", "--user-identifier" => "user_42",
    "--compliance" => "hipaa", "--system-prompt" => "Prefer primary sources",
    "--ids" => "doc_1", "--api-key" => "test_key", "--output-format" => "json"
  }.freeze

  # Flags that the exe handles before parsing, so the parser never sees them.
  HANDLED_BEFORE_PARSING = %w[--help --flags-json].freeze

  TABLES = {
    "exa-ai-search" => Exa::CLI::SearchParser::FLAGS,
    "exa-ai-get-contents" => Exa::CLI::GetContents::FLAGS
  }.freeze

  TABLES.each do |exe_name, table|
    command = exe_name.delete_prefix("exa-ai-").tr("-", "_")

    define_method("test_#{command}_table_and_its_entries_are_frozen") do
      assert_predicate table, :frozen?
      table.each do |entry|
        assert_predicate entry, :frozen?, entry[:flag]
        assert_predicate entry[:api_field], :frozen?, entry[:flag] if entry[:api_field].is_a?(Array)
      end
    end

    define_method("test_#{command}_entries_have_exactly_the_five_keys_in_order") do
      table.each { |entry| assert_equal ENTRY_KEYS, entry.keys, entry[:flag] }
    end

    define_method("test_#{command}_flag_names_are_unique") do
      flags = table.map { |entry| entry[:flag] }

      assert_equal flags.uniq, flags
    end

    define_method("test_#{command}_flags_json_prints_the_table_and_exits_without_a_request") do
      Exa::CLI::Base.stub(:resolve_api_key, ->(_) { raise "the API key must not be read" }) do
        stdout, _stderr, exit_status = run_exe_in_process(
          exe_name, "AI infrastructure startups with Series A funding", "--bogus", "--help", "--flags-json"
        )

        assert_equal 0, exit_status
        assert_equal JSON.parse(JSON.generate(table)), JSON.parse(stdout)
      end
      assert_not_requested :any, /api\.exa\.ai/
    end

    define_method("test_#{command}_help_lists_exactly_the_table_flags") do
      assert_equal table.map { |entry| entry[:flag] }.sort, help_lines_by_flag(exe_name).keys.sort
    end

    define_method("test_#{command}_reason_is_set_exactly_when_a_deprecated_flag_has_no_replacement") do
      table.each do |entry|
        if entry[:deprecated] && entry[:replacement].nil?
          assert_kind_of String, entry[:reason], entry[:flag]
          refute_empty entry[:reason], entry[:flag]
        else
          assert_nil entry[:reason], entry[:flag]
        end
      end
    end

    define_method("test_#{command}_help_says_deprecated_exactly_when_the_table_does") do
      help_lines = help_lines_by_flag(exe_name)

      table.each do |entry|
        assert_equal entry[:deprecated], help_lines.fetch(entry[:flag]).include?("Deprecated"), entry[:flag]
      end
    end
  end

  def test_search_highlights_num_sentences_entry
    entry = Exa::CLI::SearchParser::FLAGS.find { |candidate| candidate[:flag] == "--highlights-num-sentences" }

    assert_equal(
      { flag: "--highlights-num-sentences", api_field: "contents.highlights.numSentences",
        deprecated: true, replacement: "--highlights-max-characters", reason: nil },
      entry
    )
  end

  def test_subpages_is_deprecated_on_search_only
    search_entry = Exa::CLI::SearchParser::FLAGS.find { |entry| entry[:flag] == "--subpages" }
    get_contents_entry = Exa::CLI::GetContents::FLAGS.find { |entry| entry[:flag] == "--subpages" }

    assert search_entry[:deprecated]
    refute get_contents_entry[:deprecated]
  end

  def test_search_rejects_a_flag_that_is_not_in_its_table
    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-search", "AI infrastructure startups with Series A funding", "--bogus", "--api-key", "test_key"
    )

    assert_equal "Error: unknown option --bogus\n", stderr
    refute_equal 0, exit_status
  end

  def test_search_parser_reads_every_flag_in_its_table
    parsed_flags(Exa::CLI::SearchParser::FLAGS).each do |flag|
      argv = ["AI infrastructure startups with Series A funding", flag, SAMPLE_VALUES[flag]].compact

      begin
        capture_io { Exa::CLI::SearchParser.parse(argv) }
      rescue SystemExit
        flunk "SearchParser stopped on #{flag}"
      end
    end
  end

  def test_get_contents_reads_every_flag_in_its_table
    stub_request(:post, "https://api.exa.ai/contents")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    parsed_flags(Exa::CLI::GetContents::FLAGS).each do |flag|
      _stdout, stderr, exit_status = run_exe_in_process(
        "exa-ai-get-contents", "https://exa.ai", "--api-key", "test_key", flag, *[SAMPLE_VALUES[flag]].compact
      )

      refute_includes stderr, "unknown option", flag
      assert_nil exit_status, "#{flag}: #{stderr}"
    end
  end

  private

  # The table flags a command's parser reads, without the ones the exe
  # handles before it parses.
  def parsed_flags(table)
    table.map { |entry| entry[:flag] } - HANDLED_BEFORE_PARSING
  end

  # Runs the command's --help and returns a Hash from each flag that starts a
  # help line to that line. Continuation lines and the Examples section do
  # not start with a flag, so they are left out.
  def help_lines_by_flag(exe_name)
    help_text, = run_exe_in_process(exe_name, "--help")
    help_text.lines.filter_map do |line|
      flag = line[/\A\s+(--[a-z][a-z-]*)/, 1]
      [flag, line] if flag
    end.to_h
  end
end
