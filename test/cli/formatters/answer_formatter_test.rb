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
end
