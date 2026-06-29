# frozen_string_literal: true

require "test_helper"

class AgentRunFormatterTest < Minitest::Test
  def completed_run(cost_dollars:)
    Exa::Resources::AgentRun.new(
      id: "agent_run_1", object: "agent_run", status: "completed",
      output: { "text" => "Tokyo is the largest." },
      cost_dollars: cost_dollars, completed_at: "2026-06-29T18:51:05Z"
    )
  end

  # The live API returns cost_dollars as a Hash {total, search, ...}; older
  # fixtures used a bare float. The pretty formatter must render the dollar
  # total in both cases, never the raw Hash.
  def test_pretty_renders_hash_cost_as_total
    run = completed_run(cost_dollars: { "total" => 0.025, "search" => 0.015 })
    line = Exa::CLI::Formatters::AgentRunFormatter.format_run(run, "pretty").lines.grep(/Cost/).first
    assert_equal "Cost: $0.025", line.strip
  end

  def test_pretty_renders_scalar_cost
    run = completed_run(cost_dollars: 0.0423)
    line = Exa::CLI::Formatters::AgentRunFormatter.format_run(run, "pretty").lines.grep(/Cost/).first
    assert_equal "Cost: $0.0423", line.strip
  end

  def structured_run
    Exa::Resources::AgentRun.new(
      id: "agent_run_1", object: "agent_run", status: "completed",
      output: {
        "text" => "Tokyo is the capital.",
        "structured" => { "capital" => "Tokyo", "population_millions" => 36.954 },
        "grounding" => [
          { "field" => "structured", "citations" => [{ "url" => "https://example.com", "title" => "Tokyo Facts" }] }
        ]
      },
      cost_dollars: { "total" => 0.012 }
    )
  end

  def test_pretty_renders_structured_output
    out = Exa::CLI::Formatters::AgentRunFormatter.format_run(structured_run, "pretty")
    assert_includes out, "Structured:"
    assert_includes out, "\"capital\": \"Tokyo\""
    assert_includes out, "36.954"
  end

  def test_pretty_renders_grounding_from_nested_citations
    out = Exa::CLI::Formatters::AgentRunFormatter.format_run(structured_run, "pretty")
    assert_includes out, "Grounding:"
    assert_includes out, "- Tokyo Facts"
  end

  def test_text_format_appends_structured_json
    out = Exa::CLI::Formatters::AgentRunFormatter.format_run(structured_run, "text")
    assert_includes out, "{\"capital\":\"Tokyo\""
  end
end
