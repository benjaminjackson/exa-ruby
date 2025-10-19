require "test_helper"

class ResearchGetTest < Minitest::Test
  def setup
    @connection = Minitest::Mock.new
  end

  def test_initialize_with_connection_research_id_and_params
    service = Exa::Services::ResearchGet.new(
      @connection,
      research_id: "123",
      stream: true,
      events: false
    )

    assert_instance_of Exa::Services::ResearchGet, service
  end

  def test_call_gets_from_research_v1_by_id_endpoint
    stub_request(:get, "https://api.exa.ai/research/v1/123")
      .to_return(
        status: 200,
        body: {
          researchId: "123",
          createdAt: 123456,
          status: "pending",
          instructions: "test",
          model: "exa-research"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "123")
    service.call

    assert_requested :get, "https://api.exa.ai/research/v1/123"
  end

  def test_call_includes_research_id_in_path
    stub_request(:get, "https://api.exa.ai/research/v1/test-research-id-456")
      .to_return(
        status: 200,
        body: {
          researchId: "test-research-id-456",
          createdAt: 123456,
          status: "pending",
          instructions: "test",
          model: "exa-research"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "test-research-id-456")
    service.call

    assert_requested :get, "https://api.exa.ai/research/v1/test-research-id-456"
  end

  def test_call_includes_stream_query_parameter
    stub_request(:get, "https://api.exa.ai/research/v1/123")
      .with(query: { stream: "true" })
      .to_return(
        status: 200,
        body: {
          researchId: "123",
          createdAt: 123456,
          status: "pending",
          instructions: "test",
          model: "exa-research"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "123", stream: true)
    service.call

    assert_requested :get, "https://api.exa.ai/research/v1/123", query: { stream: "true" }
  end

  def test_call_includes_events_query_parameter
    stub_request(:get, "https://api.exa.ai/research/v1/123")
      .with(query: { events: "true" })
      .to_return(
        status: 200,
        body: {
          researchId: "123",
          createdAt: 123456,
          status: "pending",
          instructions: "test",
          model: "exa-research"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "123", events: true)
    service.call

    assert_requested :get, "https://api.exa.ai/research/v1/123", query: { events: "true" }
  end

  def test_call_returns_research_task_object
    stub_request(:get, "https://api.exa.ai/research/v1/123")
      .to_return(
        status: 200,
        body: {
          researchId: "123",
          createdAt: 123456,
          status: "pending",
          instructions: "test",
          model: "exa-research"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "123")
    result = service.call

    assert_instance_of Exa::Resources::ResearchTask, result
  end

  def test_call_handles_pending_status_response
    stub_request(:get, "https://api.exa.ai/research/v1/123")
      .to_return(
        status: 200,
        body: {
          researchId: "123",
          createdAt: 123456,
          status: "pending",
          instructions: "test instructions",
          model: "exa-research"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "123")
    result = service.call

    assert_equal "pending", result.status
    assert result.pending?
  end

  def test_call_handles_running_status_with_events
    stub_request(:get, "https://api.exa.ai/research/v1/123")
      .to_return(
        status: 200,
        body: {
          researchId: "123",
          createdAt: 123456,
          status: "running",
          instructions: "test",
          model: "exa-research",
          events: [
            { type: "search", timestamp: 123457, data: { query: "test query" } }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "123")
    result = service.call

    assert_equal "running", result.status
    assert result.running?
    refute_nil result.events
    assert_equal 1, result.events.length
  end

  def test_call_handles_completed_status_with_output
    stub_request(:get, "https://api.exa.ai/research/v1/123")
      .to_return(
        status: 200,
        body: {
          researchId: "123",
          createdAt: 123456,
          status: "completed",
          instructions: "test",
          model: "exa-research",
          output: { content: "research output" },
          costDollars: { total: 0.05, search: 0.02, llm: 0.03 },
          finishedAt: 123789
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "123")
    result = service.call

    assert_equal "completed", result.status
    assert result.completed?
    refute_nil result.output
    refute_nil result.cost_dollars
    assert_equal 0.05, result.cost_dollars["total"]
  end

  def test_call_handles_failed_status_with_error
    stub_request(:get, "https://api.exa.ai/research/v1/123")
      .to_return(
        status: 200,
        body: {
          researchId: "123",
          createdAt: 123456,
          status: "failed",
          instructions: "test",
          model: "exa-research",
          error: "error message",
          finishedAt: 123789
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "123")
    result = service.call

    assert_equal "failed", result.status
    assert result.failed?
    assert_equal "error message", result.error
  end

  def test_call_handles_canceled_status
    stub_request(:get, "https://api.exa.ai/research/v1/123")
      .to_return(
        status: 200,
        body: {
          researchId: "123",
          createdAt: 123456,
          status: "canceled",
          instructions: "test",
          model: "exa-research",
          finishedAt: 123789
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "123")
    result = service.call

    assert_equal "canceled", result.status
    assert result.canceled?
  end

  def test_call_maps_all_fields_from_response
    stub_request(:get, "https://api.exa.ai/research/v1/123")
      .to_return(
        status: 200,
        body: {
          researchId: "123",
          createdAt: 123456,
          status: "completed",
          instructions: "test instructions",
          model: "exa-research",
          outputSchema: { type: "object" },
          events: [{ type: "search" }],
          output: { content: "result" },
          costDollars: { total: 0.05 },
          finishedAt: 123789,
          error: nil
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "123")
    result = service.call

    assert_equal "123", result.research_id
    assert_equal 123456, result.created_at
    assert_equal "completed", result.status
    assert_equal "test instructions", result.instructions
    assert_equal "exa-research", result.model
    refute_nil result.output_schema
    refute_nil result.events
    refute_nil result.output
    refute_nil result.cost_dollars
    assert_equal 123789, result.finished_at
  end

  def test_call_raises_not_found_on_404
    stub_request(:get, "https://api.exa.ai/research/v1/123")
      .to_return(
        status: 404,
        body: { error: "Research task not found" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "123")

    assert_raises(Exa::NotFound) do
      service.call
    end
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:get, "https://api.exa.ai/research/v1/123")
      .to_return(
        status: 401,
        body: { error: "Unauthorized" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "123")

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end

  def test_call_raises_server_error_on_500
    stub_request(:get, "https://api.exa.ai/research/v1/123")
      .to_return(
        status: 500,
        body: { error: "Internal server error" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    connection = Exa::Connection.build(api_key: "test_key")
    service = Exa::Services::ResearchGet.new(connection, research_id: "123")

    assert_raises(Exa::InternalServerError) do
      service.call
    end
  end
end
