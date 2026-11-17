# frozen_string_literal: true

require "test_helper"

class Exa::CLI::FindSimilarExeTest < Minitest::Test
  # exa-ai-find-similar has its own category check. It must reject
  # --category github and exit before it sends a request. The stub keeps
  # the request local if the check ever stops working.
  def test_exe_rejects_category_github
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-find-similar", "https://arxiv.org/abs/2307.06435",
      "--category", "github", "--api-key", "test_key"
    )

    assert_equal 1, exit_status
    assert_includes stderr, "Category must be one of"
    assert_not_requested :post, "https://api.exa.ai/findSimilar"
  end

  def test_exe_sends_highlights_query_links_and_snapshot_in_contents
    body = post_find_similar(
      "--highlights", "--highlights-query", "key points",
      "--links", "3", "--snapshot-as-of", "2026-01-01T00:00:00Z"
    )

    assert_equal "key points", body.dig("contents", "highlights", "query")
    assert_equal 3, body.dig("contents", "extras", "links")
    assert_equal "2026-01-01T00:00:00Z", body.dig("contents", "snapshotAsOf")
  end

  def test_exe_keeps_text_and_summary_contents_unchanged
    body = post_find_similar("--text", "--text-max-characters", "100", "--summary")

    assert_equal({ "text" => { "maxCharacters" => 100 }, "summary" => true }, body["contents"])
  end

  def test_exe_sends_sub_options_without_their_parent_flags
    body = post_find_similar(
      "--text-max-characters", "3000", "--summary-query", "Name the authors",
      "--context-max-characters", "500", "--highlights-query", "key findings"
    )

    expected_contents = {
      "text" => { "maxCharacters" => 3000 }, "summary" => { "query" => "Name the authors" },
      "context" => { "maxCharacters" => 500 }, "highlights" => { "query" => "key findings" }
    }
    assert_equal expected_contents, body["contents"]
  end

  def test_exe_rejects_subpage_target_without_value
    _stdout, stderr, status = run_find_similar_expecting_no_request("--subpage-target")

    assert_equal 1, status
    assert_equal "Error: --subpage-target needs a value\n", stderr
  end

  def test_exe_rejects_flag_as_subpage_target_value
    _stdout, stderr, status = run_find_similar_expecting_no_request("--subpage-target", "--text")

    assert_equal 1, status
    assert_equal "Error: --subpage-target needs a value (got the flag --text)\n", stderr
  end

  def test_exe_rejects_flag_as_summary_query_value
    _stdout, stderr, status = run_find_similar_expecting_no_request("--summary", "--summary-query", "--text")

    assert_equal 1, status
    assert_equal "Error: --summary-query needs a value (got the flag --text)\n", stderr
  end

  def test_exe_rejects_summary_query_without_value
    _stdout, stderr, status = run_find_similar_expecting_no_request("--summary", "--summary-query")

    assert_equal 1, status
    assert_equal "Error: --summary-query needs a value\n", stderr
  end

  def test_exe_rejects_flag_as_highlights_query_value
    _stdout, stderr, status = run_find_similar_expecting_no_request("--highlights-query", "--livecrawl")

    assert_equal 1, status
    assert_equal "Error: --highlights-query needs a value (got the flag --livecrawl)\n", stderr
  end

  def test_exe_rejects_snapshot_as_of_without_value
    _stdout, stderr, status = run_find_similar_expecting_no_request("--snapshot-as-of")

    assert_equal 1, status
    assert_equal "Error: --snapshot-as-of needs a value\n", stderr
  end

  def test_exe_keeps_summary_query_with_a_single_dash
    body = post_find_similar("--summary", "--summary-query", "state-of-the-art chip designs")

    assert_equal({ "query" => "state-of-the-art chip designs" }, body.dig("contents", "summary"))
  end

  def test_exe_keeps_highlights_query_that_starts_with_two_dashes_and_contains_a_space
    body = post_find_similar("--highlights", "--highlights-query", "--autosquash behavior")

    assert_equal({ "query" => "--autosquash behavior" }, body.dig("contents", "highlights"))
  end

  def test_exe_rejects_unknown_flag_before_the_url
    stub_request(:post, "https://api.exa.ai/findSimilar")

    _stdout, stderr, status = run_exe_in_process(
      "exa-ai-find-similar", "--highlight", "https://arxiv.org/abs/2307.06435", "--api-key", "test_key"
    )

    assert_equal 1, status
    assert_equal "Error: unknown option --highlight\n", stderr
    assert_not_requested :post, "https://api.exa.ai/findSimilar"
  end

  def test_help_lists_every_content_extraction_flag_of_search
    search_help, = run_exe_in_process("exa-ai-search", "--help")
    find_similar_help, = run_exe_in_process("exa-ai-find-similar", "--help")
    section = search_help[/^Content Extraction:\n(.*?)\n\n/m, 1]
    search_flags = section.scan(/^\s+(--[a-z-]+)/).flatten

    refute_empty search_flags
    search_flags.each do |flag|
      assert_match(/^\s+#{Regexp.escape(flag)}\b/, find_similar_help, "find-similar help is missing #{flag}")
    end
  end

  # find-similar has no flag table, so its flags are read from its help
  # text. Every flag there that is not in this list takes a value.
  FIND_SIMILAR_FLAGS_WITHOUT_VALUE = %w[
    --exclude-source-domain --text --include-html-tags --summary --context
    --highlights --livecrawl --help
  ].freeze

  # find-similar has no --strict, so --text stands in as the next flag.
  def test_exe_stops_when_a_value_flag_has_no_value_or_gets_a_flag_as_its_value
    help_text, = run_exe_in_process("exa-ai-find-similar", "--help")
    help_flags = help_text.scan(/^\s+(--[a-z][a-z-]*)/).flatten.uniq
    assert_includes help_flags, "--api-key"

    (help_flags - FIND_SIMILAR_FLAGS_WITHOUT_VALUE).each do |flag|
      [[], ["--text"]].each do |rest|
        _stdout, stderr, exit_status = run_find_similar_expecting_no_request(flag, *rest)
        case_name = [flag, *rest].join(" ")

        assert_equal 1, exit_status, "#{case_name}: #{stderr}"
        assert_equal 1, stderr.lines.size, "#{case_name}: #{stderr}"
        assert_match(/\AError: #{Regexp.escape(flag)}(?![\w-])/, stderr, case_name)
      end
    end
  end

  def test_exe_api_key_and_output_format_reject_the_next_flag_as_value
    %w[--api-key --output-format].each do |flag|
      _stdout, stderr, exit_status = run_find_similar_expecting_no_request(flag, "--output-format", "json")

      assert_equal 1, exit_status
      assert_equal "Error: #{flag} needs a value (got the flag --output-format)\n", stderr
    end
  end

  def test_exe_keeps_a_free_text_value_that_starts_with_dashes_and_has_whitespace
    body = post_find_similar("--include-text", "--seed round announced")

    assert_equal ["--seed round announced"], body["includeText"]
  end

  private

  # Runs exa-ai-find-similar in-process with the given flags after the URL,
  # checks that no request was sent, and returns stdout, stderr and status.
  def run_find_similar_expecting_no_request(*flags)
    stub_request(:post, "https://api.exa.ai/findSimilar")
    result = run_exe_in_process("exa-ai-find-similar", "https://arxiv.org/abs/2307.06435", "--api-key", "test_key", *flags)
    assert_not_requested :post, "https://api.exa.ai/findSimilar"
    result
  end

  # Runs exa-ai-find-similar in-process with the given flags and returns
  # the parsed body of the request it sends.
  def post_find_similar(*flags)
    posted_body = nil
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    run_exe_in_process("exa-ai-find-similar", "https://arxiv.org/abs/2307.06435", "--api-key", "test_key", *flags)
    posted_body
  end
end
