# frozen_string_literal: true

require "test_helper"

# Checks that the commands use the option helpers on Exa::CLI::Base, and
# that a bad or missing option value stops the command before any request.
class OptionParsingTest < Minitest::Test
  COMMAND_FILES = (Dir[File.expand_path("../../exe/*", __dir__)] +
                   [File.expand_path("../../lib/exa/cli/search_parser.rb", __dir__)]).freeze

  # Matches .to_i called directly on a value read from the arguments, such as
  # args.shift.to_i or argv[i + 1].to_i. Other .to_i calls are not options.
  OPTION_TO_I = /(?:\.shift|\[i \+ 1\])&?\.to_i\b/

  def test_no_command_defines_its_own_json_parsing_helper
    offenders = COMMAND_FILES.select { |path| File.read(path).match?(/def parse_json_(or_file|arg)\b/) }

    assert_empty offenders.map { |path| File.basename(path) }
  end

  def test_no_command_converts_an_option_value_with_to_i
    offenders = COMMAND_FILES.select { |path| File.read(path).match?(OPTION_TO_I) }

    assert_empty offenders.map { |path| File.basename(path) }
  end

  def test_search_monitor_list_rejects_limit_that_is_not_a_number
    stub_request(:any, /exa\.ai/)

    _stdout, stderr, status = run_exe_in_process(
      "exa-ai-search-monitor-list", "--api-key", "test_key", "--limit", "abc"
    )

    assert_equal 1, status
    assert_equal "Error: --limit must be a number (got \"abc\")\n", stderr
    assert_not_requested :any, /exa\.ai/
  end

  def test_search_monitor_create_rejects_include_domains_without_value
    stub_request(:any, /exa\.ai/)

    _stdout, stderr, status = run_exe_in_process(
      "exa-ai-search-monitor-create", "--api-key", "test_key",
      "--query", "AI/ML infrastructure startups with Series A funding",
      "--webhook-url", "https://example.com/hook", "--include-domains"
    )

    assert_equal 1, status
    assert_equal "Error: --include-domains needs a value\n", stderr
    assert_not_requested :any, /exa\.ai/
  end

  def test_get_contents_rejects_ids_without_value
    stub_request(:any, /exa\.ai/)

    _stdout, stderr, status = run_exe_in_process(
      "exa-ai-get-contents", "https://example.com/article", "--api-key", "test_key", "--ids"
    )

    assert_equal 1, status
    assert_equal "Error: --ids needs a value\n", stderr
    assert_not_requested :any, /exa\.ai/
  end
end
