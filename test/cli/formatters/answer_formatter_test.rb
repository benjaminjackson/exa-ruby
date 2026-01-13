# frozen_string_literal: true

require "test_helper"
require "exa/cli/formatters/answer_formatter"

class Exa::CLI::Formatters::AnswerFormatterTest < Minitest::Test
  def setup
    @result = Exa::Resources::Answer.new(
      answer: "SpaceX's valuation as of late 2024 is approximately $180 billion.",
      citations: [
        {
          "title" => "SpaceX Valuation in 2024",
          "url" => "https://example.com/spacex-valuation",
          "author" => "John Smith",
          "publishedDate" => "2024-06-15"
        },
        {
          "title" => "Latest SpaceX Funding Round",
          "url" => "https://example.com/spacex-funding",
          "author" => "Jane Doe",
          "publishedDate" => "2024-08-20"
        }
      ],
      cost_dollars: 0.005
    )
  end

  def test_json_format_returns_json_string
    output = Exa::CLI::Formatters::AnswerFormatter.format(@result, "json")

    parsed = JSON.parse(output)
    assert_equal "SpaceX's valuation as of late 2024 is approximately $180 billion.", parsed["answer"]
    assert_equal 2, parsed["citations"].length
    assert_equal 0.005, parsed["cost_dollars"]
  end

  def test_pretty_format_shows_answer_and_citations
    output = Exa::CLI::Formatters::AnswerFormatter.format(@result, "pretty")

    assert_includes output, "Answer:"
    assert_includes output, "SpaceX's valuation as of late 2024 is approximately $180 billion."
    assert_includes output, "Citations:"
    assert_includes output, "[1] SpaceX Valuation in 2024"
    assert_includes output, "https://example.com/spacex-valuation"
    assert_includes output, "John Smith"
    assert_includes output, "2024-06-15"
    assert_includes output, "[2] Latest SpaceX Funding Round"
    assert_includes output, "Cost: $0.005"
  end

  def test_text_format_shows_answer_only
    output = Exa::CLI::Formatters::AnswerFormatter.format(@result, "text")

    assert_equal "SpaceX's valuation as of late 2024 is approximately $180 billion.", output
  end

  def test_default_format_is_json
    output = Exa::CLI::Formatters::AnswerFormatter.format(@result, nil)

    parsed = JSON.parse(output)
    assert parsed["answer"]
  end

  def test_json_format_with_structured_answer
    structured_answer = { "city" => "Albany", "state" => "New York" }
    result = Exa::Resources::Answer.new(
      answer: structured_answer,
      citations: [{ "title" => "Wikipedia", "url" => "https://example.com" }],
      cost_dollars: 0.01
    )

    output = Exa::CLI::Formatters::AnswerFormatter.format(result, "json")

    parsed = JSON.parse(output)
    assert_equal "Albany", parsed["answer"]["city"]
    assert_equal "New York", parsed["answer"]["state"]
  end

  def test_pretty_format_with_structured_answer
    structured_answer = { "city" => "Albany", "state" => "New York" }
    result = Exa::Resources::Answer.new(
      answer: structured_answer,
      citations: [{ "title" => "Wikipedia", "url" => "https://example.com" }],
      cost_dollars: 0.01
    )

    output = Exa::CLI::Formatters::AnswerFormatter.format(result, "pretty")

    # Should show formatted JSON or similar structured representation
    assert_includes output, "Albany"
    assert_includes output, "New York"
  end

  def test_text_format_with_structured_answer
    structured_answer = { "city" => "Albany", "state" => "New York" }
    result = Exa::Resources::Answer.new(
      answer: structured_answer,
      citations: [],
      cost_dollars: 0.01
    )

    output = Exa::CLI::Formatters::AnswerFormatter.format(result, "text")

    # For structured answers, text format should show JSON representation
    assert_includes output, "Albany"
    assert_includes output, "New York"
  end

  def test_toon_format_returns_toon_string
    output = Exa::CLI::Formatters::AnswerFormatter.format(@result, "toon")

    assert_instance_of String, output
    assert_includes output, "SpaceX"
    assert_includes output, "180 billion"

    # TOON should be more compact than JSON
    json_output = Exa::CLI::Formatters::AnswerFormatter.format(@result, "json")
    assert output.length < json_output.length
  end

  def test_json_format_with_skip_citations_removes_citations
    output = Exa::CLI::Formatters::AnswerFormatter.format(@result, "json", skip_citations: true)

    parsed = JSON.parse(output)
    assert_equal "SpaceX's valuation as of late 2024 is approximately $180 billion.", parsed["answer"]
    refute parsed.key?("citations")
    assert_equal 0.005, parsed["cost_dollars"]
  end

  def test_pretty_format_with_skip_citations_hides_citations_section
    output = Exa::CLI::Formatters::AnswerFormatter.format(@result, "pretty", skip_citations: true)

    assert_includes output, "Answer:"
    assert_includes output, "SpaceX's valuation as of late 2024 is approximately $180 billion."
    refute_includes output, "Citations:"
    refute_includes output, "[1] SpaceX Valuation in 2024"
    refute_includes output, "https://example.com/spacex-valuation"
    assert_includes output, "Cost: $0.005"
  end

  def test_json_format_without_skip_citations_includes_citations
    output = Exa::CLI::Formatters::AnswerFormatter.format(@result, "json", skip_citations: false)

    parsed = JSON.parse(output)
    assert_equal 2, parsed["citations"].length
  end

  def test_pretty_format_without_skip_citations_shows_citations_section
    output = Exa::CLI::Formatters::AnswerFormatter.format(@result, "pretty", skip_citations: false)

    assert_includes output, "Citations:"
    assert_includes output, "[1] SpaceX Valuation in 2024"
    assert_includes output, "[2] Latest SpaceX Funding Round"
  end
end
