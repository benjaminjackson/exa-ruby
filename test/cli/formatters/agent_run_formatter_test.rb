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

  def deletion
    Exa::Resources::AgentRunDeletion.new(id: "run_abc123", object: "agent_run.deleted", deleted: true)
  end

  def test_format_deletion_in_every_format_does_not_raise
    assert_includes Exa::CLI::Formatters::AgentRunFormatter.format_deletion(deletion, "pretty"), "Deleted agent run: run_abc123"
    assert_equal "run_abc123 DELETED", Exa::CLI::Formatters::AgentRunFormatter.format_deletion(deletion, "text")
    json = JSON.parse(Exa::CLI::Formatters::AgentRunFormatter.format_deletion(deletion, "json"))
    assert_equal({ "id" => "run_abc123", "object" => "agent_run.deleted", "deleted" => true }, json)
    assert_includes Exa::CLI::Formatters::AgentRunFormatter.format_deletion(deletion, "toon"), "run_abc123"
  end

  def failed_run
    Exa::Resources::AgentRun.new(
      id: "agent_run_2", object: "agent_run", status: "failed", stop_reason: "error",
      error: { "type" => "agent_error", "code" => "budget_exceeded", "message" => "Run stopped at the cost limit" }
    )
  end

  def test_pretty_prints_error_and_stop_reason_on_separate_lines
    out = Exa::CLI::Formatters::AgentRunFormatter.format_run(failed_run, "pretty")
    assert_includes out, "Error: agent_error (budget_exceeded): Run stopped at the cost limit"
    assert_includes out, "Stop reason: error"
  end

  def test_text_prints_error_for_failed_run
    out = Exa::CLI::Formatters::AgentRunFormatter.format_run(failed_run, "text")
    assert_includes out, "Error: agent_error (budget_exceeded): Run stopped at the cost limit"
  end
end
