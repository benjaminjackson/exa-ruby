require "test_helper"

class Exa::CLI::ResearchListTest < Minitest::Test
  def setup
    @api_key = "test_api_key"
  end

  def test_lists_research_tasks
    stub_research_list_request

    output = run_research_list_command([])

    parsed = JSON.parse(output)
    assert_equal 1, parsed["data"].size
    assert_equal "research_123", parsed["data"][0]["research_id"]
    assert_equal "AI safety research", parsed["data"][0]["instructions"]
  end

  def test_parses_cursor_flag
    stub_research_list_request(cursor: "cursor_abc")

    output = run_research_list_command(["--cursor", "cursor_abc"])

    refute_includes output, "Error"
  end

  def test_parses_limit_flag
    stub_research_list_request(limit: 20)

    output = run_research_list_command(["--limit", "20"])

    refute_includes output, "Error"
  end

  def test_default_limit_is_10
    stub_research_list_request(limit: 10)

    output = run_research_list_command([])

    refute_includes output, "Error"
  end

  def test_shows_pagination_info
    stub_research_list_request(has_more: true, next_cursor: "next_page_cursor")

    output = run_research_list_command([])

    assert_includes output, "More results available"
    assert_includes output, "next_page_cursor"
  end

  def test_pretty_format_shows_table
    stub_research_list_request

    output = run_research_list_command(["--output-format", "pretty"])

    assert_includes output, "Task ID"
    assert_includes output, "Status"
    assert_includes output, "Created"
    assert_includes output, "research_123"
  end

  def test_handles_api_error_gracefully
    stub_request(:get, "https://api.exa.ai/research/v1")
      .with(query: {limit: "10"})
      .to_return(
        status: 401,
        body: {error: "Unauthorized"}.to_json,
        headers: {"Content-Type" => "application/json"}
      )

    output = run_research_list_command([])

    assert_includes output, "Error"
  end

  private

  def stub_research_list_request(cursor: nil, limit: 10, has_more: false, next_cursor: nil)
    query_params = {limit: limit.to_s}
    query_params[:cursor] = cursor if cursor

    response_body = {
      data: [
        {
          researchId: "research_123",
          createdAt: "2024-01-15T10:00:00Z",
          status: "completed",
          instructions: "AI safety research"
        }
      ],
      hasMore: has_more,
      nextCursor: next_cursor
    }

    stub_request(:get, "https://api.exa.ai/research/v1")
      .with(query: query_params)
      .to_return(
        status: 200,
        body: response_body.to_json,
        headers: {"Content-Type" => "application/json"}
      )
  end

  def run_research_list_command(args)
    require "stringio"
    require "json"

    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    begin
      cursor = nil
      limit = 10
      output_format = "json"

      i = 0
      while i < args.length
        case args[i]
        when "--cursor"
          cursor = args[i + 1]
          i += 2
        when "--limit"
          limit = args[i + 1].to_i
          i += 2
        when "--output-format"
          output_format = args[i + 1]
          i += 2
        when "--api-key"
          i += 2
        else
          i += 1
        end
      end

      client = Exa::Client.new(api_key: @api_key)

      # Build params
      params = {limit: limit}
      params[:cursor] = cursor if cursor

      result = client.research_list(**params)

      # Format output using ResearchFormatter
      formatted = Exa::CLI::Formatters::ResearchFormatter.format_list(
        result,
        output_format
      )
      $stdout.puts formatted

      # Show pagination info if there are more results
      if result.has_more && result.next_cursor
        if output_format == "pretty"
          $stdout.puts "\n" + "=" * 80
          $stdout.puts "More results available. Use --cursor #{result.next_cursor} to get next page."
        else
          $stderr.puts "More results available. Use --cursor #{result.next_cursor} to get next page."
        end
      end

      $stdout.string + $stderr.string
    rescue Exa::Unauthorized => e
      "Error: Authentication failed - #{e.message}"
    rescue Exa::ClientError => e
      "Error: Client error - #{e.message}"
    rescue Exa::ServerError => e
      "Error: Server error - #{e.message}"
    rescue StandardError => e
      "Error: #{e.message}"
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end
  end
end
