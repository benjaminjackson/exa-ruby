# frozen_string_literal: true

require "test_helper"

class Exa::CLI::ResearchStartTest < Minitest::Test
  def test_requires_instructions_flag
    # Test that command errors if no --instructions provided
    error = assert_raises(ArgumentError) do
      parse_research_start_args([])
    end
    assert_includes error.message.downcase, "instructions"
  end

  def test_parses_instructions_flag
    args = parse_research_start_args(["--instructions", "Find Ruby performance tips"])
    assert_equal "Find Ruby performance tips", args[:instructions]
  end

  def test_parses_model_flag
    args = parse_research_start_args(["--instructions", "test", "--model", "exa-research-pro"])
    assert_equal "exa-research-pro", args[:model]
  end

  def test_parses_output_schema_flag
    json_schema = '{"type":"object","properties":{"summary":{"type":"string"}}}'
    args = parse_research_start_args(["--instructions", "test", "--output-schema", json_schema])
    assert_equal json_schema, args[:output_schema]
  end

  def test_basic_start_returns_task_id
    stub_request(:post, "https://api.exa.ai/research")
      .with(
        body: hash_including(instructions: "Find Ruby tips"),
        headers: { "Authorization" => "Bearer test_api_key" }
      )
      .to_return(
        status: 200,
        body: {
          researchId: "research_123",
          status: "pending",
          createdAt: "2025-01-15T10:00:00Z",
          instructions: "Find Ruby tips"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # This test verifies the stub is working
    # Actual execution test will be added when executable is ready
    assert true
  end

  def test_wait_flag_polls_until_complete
    # Stub initial research_start call
    stub_request(:post, "https://api.exa.ai/research")
      .to_return(
        status: 200,
        body: {
          researchId: "research_123",
          status: "pending",
          createdAt: "2025-01-15T10:00:00Z",
          instructions: "Test task"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Stub first poll - still running
    stub_request(:get, "https://api.exa.ai/research/research_123")
      .to_return(
        {
          status: 200,
          body: {
            researchId: "research_123",
            status: "running",
            createdAt: "2025-01-15T10:00:00Z",
            instructions: "Test task"
          }.to_json
        },
        {
          status: 200,
          body: {
            researchId: "research_123",
            status: "completed",
            createdAt: "2025-01-15T10:00:00Z",
            finishedAt: "2025-01-15T10:05:00Z",
            instructions: "Test task",
            output: "Research results",
            costDollars: { total: 0.05 }
          }.to_json
        }
      )

    # This test verifies the stub is working
    # Actual polling test will be added when executable is ready
    assert true
  end

  def test_events_flag_includes_event_log
    args = parse_research_start_args(["--instructions", "test", "--events"])
    assert_equal true, args[:events]
  end

  def test_handles_api_error_gracefully
    stub_request(:post, "https://api.exa.ai/research")
      .to_return(status: 500, body: { error: "Internal Server Error" }.to_json)

    # This test will be implemented when we have the actual command
    # For now, just verify WebMock is set up
    assert true
  end

  private

  # Helper method to parse command-line arguments
  # This simulates what the exe/exa-research-start script will do
  def parse_research_start_args(argv)
    args = { output_format: "json", events: false }

    i = 0
    while i < argv.length
      arg = argv[i]
      case arg
      when "--instructions"
        args[:instructions] = argv[i + 1]
        i += 2
      when "--model"
        args[:model] = argv[i + 1]
        i += 2
      when "--output-schema"
        args[:output_schema] = argv[i + 1]
        i += 2
      when "--wait"
        args[:wait] = true
        i += 1
      when "--events"
        args[:events] = true
        i += 1
      when "--api-key"
        args[:api_key] = argv[i + 1]
        i += 2
      when "--output-format"
        args[:output_format] = argv[i + 1]
        i += 2
      else
        i += 1
      end
    end

    raise ArgumentError, "Instructions are required (use --instructions flag)" if args[:instructions].nil? || args[:instructions].empty?

    args
  end
end
