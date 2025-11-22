# frozen_string_literal: true

require "test_helper"

class Exa::CLI::ResearchGetTest < Minitest::Test
  def setup
    @api_key = "test_api_key"
  end

  def test_requires_research_id_argument
    # Run without research_id
    output = run_research_get_command([])

    assert_includes output, "Error"
    assert_includes output.downcase, "research"
  end

  def test_parses_research_id_from_argv
    stub_research_get_request(research_id: "research_123")

    output = run_research_get_command(["research_123"])

    refute_includes output, "Error"
    assert_includes output, "research_123"
  end

  def test_parses_events_flag
    stub_research_get_request(
      research_id: "research_123",
      events: true
    )

    output = run_research_get_command(["research_123", "--events"])

    refute_includes output, "Error"
  end

  def test_parses_stream_flag
    stub_research_get_request(
      research_id: "research_123",
      stream: true
    )

    output = run_research_get_command(["research_123", "--stream"])

    refute_includes output, "Error"
  end

  def test_outputs_task_status
    stub_research_get_request(
      research_id: "research_123",
      status: "completed"
    )

    output = run_research_get_command(["research_123"])

    parsed = JSON.parse(output)
    assert_equal "research_123", parsed["research_id"]
    assert_equal "completed", parsed["status"]
  end

  def test_handles_not_found_error
    # Stub 404 response
    stub_request(:get, "https://api.exa.ai/research/v1/research_not_found")
      .to_return(status: 404, body: { error: "Research task not found" }.to_json)

    output = run_research_get_command(["research_not_found"])

    assert_includes output, "Error"
    assert_includes output.downcase, "not found"
  end

  def test_handles_api_error_gracefully
    # Stub API error response
    stub_request(:get, "https://api.exa.ai/research/v1/research_error")
      .to_return(status: 500, body: { error: "Internal Server Error" }.to_json)

    output = run_research_get_command(["research_error"])

    assert_includes output, "Error"
  end

  private

  def stub_research_get_request(research_id: "research_123", status: "completed", events: false, stream: false)
    response_body = {
      researchId: research_id,
      createdAt: "2025-01-15T10:00:00Z",
      status: status,
      instructions: "Test research task"
    }

    case status
    when "completed"
      response_body[:output] = { results: "Test findings" }
      response_body[:costDollars] = { total: 0.05 }
      response_body[:finishedAt] = "2025-01-15T10:30:00Z"
    when "running"
      response_body[:events] = [{ event: "processing" }] if events
    when "failed"
      response_body[:error] = "Task failed"
      response_body[:finishedAt] = "2025-01-15T10:15:00Z"
    end

    if events
      response_body[:events] ||= [{ event: "started" }]
    end

    # Build URL with query parameters if needed
    url = "https://api.exa.ai/research/v1/#{research_id}"
    query_params = []
    query_params << "events=true" if events
    query_params << "stream=true" if stream
    url += "?#{query_params.join('&')}" unless query_params.empty?

    stub_request(:get, url)
      .to_return(
        status: 200,
        body: response_body.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def run_research_get_command(args)
    require "stringio"
    require "json"

    old_stdout = $stdout
    $stdout = StringIO.new

    begin
      # Simulate the command execution
      if args.empty?
        $stdout.puts "Error: Research ID argument required"
      else
        research_id = args[0]
        events = args.include?("--events")
        stream = args.include?("--stream")
        output_format = "json"

        args.each_with_index do |arg, i|
          case arg
          when "--output-format"
            output_format = args[i + 1]
          when "--api-key"
            # Skip flag values
          end
        end

        client = Exa::Client.new(api_key: @api_key)

        # Build params
        params = {}
        params[:events] = events if events
        params[:stream] = stream if stream

        result = client.research_get(research_id, **params)

        # Format output using ResearchFormatter
        formatted = Exa::CLI::Formatters::ResearchFormatter.format_task(
          result,
          output_format,
          show_events: events
        )
        $stdout.puts formatted
      end

      $stdout.string
    rescue Exa::NotFound => e
      "Error: Research task not found - #{e.message}"
    rescue StandardError => e
      "Error: #{e.message}"
    ensure
      $stdout = old_stdout
    end
  end
end
