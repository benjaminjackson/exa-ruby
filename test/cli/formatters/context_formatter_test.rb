# frozen_string_literal: true

require "test_helper"
require "exa/cli/formatters/context_formatter"

class Exa::CLI::Formatters::ContextFormatterTest < Minitest::Test
  def setup
    @result = Exa::Resources::ContextResult.new(
      request_id: "req_123",
      query: "ruby authentication",
      response: "Sample code:\n\n```ruby\ndef authenticate(token)\n  verify(token)\nend\n```",
      results_count: 5,
      cost_dollars: 0.0025,
      search_time: 150,
      output_tokens: 100
    )
  end

  def test_json_format_returns_json_string
    output = Exa::CLI::Formatters::ContextFormatter.format(@result, "json")

    parsed = JSON.parse(output)
    assert_equal "req_123", parsed["request_id"]
    assert_equal "ruby authentication", parsed["query"]
    assert_equal 5, parsed["results_count"]
    assert_equal 0.0025, parsed["cost_dollars"]
    assert_equal 150, parsed["search_time"]
    assert_equal 100, parsed["output_tokens"]
    assert_includes parsed["response"], "Sample code"
  end

  def test_pretty_format_shows_metadata_and_context
    output = Exa::CLI::Formatters::ContextFormatter.format(@result, "pretty")

    assert_includes output, "Query: ruby authentication"
    assert_includes output, "Request ID:   req_123"
    assert_includes output, "Results:      5"
    assert_includes output, "Cost:         $0.0025"
    assert_includes output, "Search Time:  150ms"
    assert_includes output, "Code Context:"
    assert_includes output, "Sample code"
    assert_includes output, "def authenticate"
    assert_includes output, "="
  end

  def test_text_format_shows_code_snippets
    output = Exa::CLI::Formatters::ContextFormatter.format(@result, "text")

    assert_includes output, "Query: ruby authentication"
    assert_includes output, "Request ID: req_123"
    assert_includes output, "Results: 5"
    assert_includes output, "Cost: $0.0025"
    assert_includes output, "Search Time: 150ms"
    assert_includes output, "Code Context:"
    assert_includes output, "Sample code"
    assert_includes output, "def authenticate"
  end
end
