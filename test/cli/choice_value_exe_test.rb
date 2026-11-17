# frozen_string_literal: true

require "test_helper"

# A flag that takes one of a fixed set of values must stop the command with
# one "Error: <flag> must be one of" line and send no request when it gets
# any other value.
class Exa::CLI::ChoiceValueExeTest < Minitest::Test
  SEARCH_QUERY = "AI/ML infrastructure startups with Series A funding"
  PAPER_URL = "https://arxiv.org/abs/2307.06435"

  def test_search_rejects_an_invalid_choice_value_with_one_error_line
    [%w[--type quick], %w[--category foo], %w[--compliance x], %w[--text-verbosity loud]].each do |flag, value|
      assert_rejects_choice("exa-ai-search", "https://api.exa.ai/search", [SEARCH_QUERY], flag, value)
    end
  end

  def test_find_similar_rejects_an_invalid_choice_value_with_one_error_line
    [%w[--category foo], %w[--text-verbosity loud]].each do |flag, value|
      assert_rejects_choice("exa-ai-find-similar", "https://api.exa.ai/findSimilar", [PAPER_URL], flag, value)
    end
  end

  def test_get_contents_rejects_an_invalid_choice_value_with_one_error_line
    [%w[--compliance x], %w[--text-verbosity loud], %w[--highlights-verbosity loud]].each do |flag, value|
      assert_rejects_choice("exa-ai-get-contents", "https://api.exa.ai/contents", [PAPER_URL], flag, value)
    end
  end

  private

  # Runs the command with flag and value and checks that it prints one
  # error line that names the flag, exits 1 and sends no request.
  def assert_rejects_choice(exe_name, endpoint, positional, flag, value)
    stub_request(:post, endpoint)
    _stdout, stderr, exit_status = run_exe_in_process(exe_name, *positional, flag, value, "--api-key", "test_key")
    case_name = "#{exe_name} #{flag} #{value}"

    assert_equal 1, exit_status, "#{case_name}: #{stderr}"
    assert_equal 1, stderr.lines.size, "#{case_name}: #{stderr}"
    assert_match(/\AError: #{Regexp.escape(flag)} must be one of: /, stderr, case_name)
    assert_not_requested :post, endpoint
  end
end
