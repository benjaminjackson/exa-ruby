require "test_helper"

class ResearchListServiceTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
  end

  def test_initialize_with_connection_and_params
    service = Exa::Services::ResearchList.new(@connection, limit: 10)
    assert_instance_of Exa::Services::ResearchList, service
  end

  def test_call_gets_from_research_v1_endpoint
    stub_request(:get, "https://api.exa.ai/research/v1")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchList.new(@connection)
    service.call

    assert_requested :get, "https://api.exa.ai/research/v1"
  end

  def test_call_includes_cursor_parameter
    stub_request(:get, "https://api.exa.ai/research/v1?cursor=abc123")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchList.new(@connection, cursor: "abc123")
    service.call

    assert_requested :get, "https://api.exa.ai/research/v1?cursor=abc123"
  end

  def test_call_includes_limit_parameter
    stub_request(:get, "https://api.exa.ai/research/v1?limit=25")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchList.new(@connection, limit: 25)
    service.call

    assert_requested :get, "https://api.exa.ai/research/v1?limit=25"
  end

  def test_call_returns_research_list_object
    stub_request(:get, "https://api.exa.ai/research/v1")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchList.new(@connection)
    result = service.call

    assert_instance_of Exa::Resources::ResearchList, result
  end

  def test_call_maps_data_array_to_research_task_objects
    task_data = {
      researchId: "task123",
      createdAt: "2025-01-01T00:00:00Z",
      status: "completed",
      instructions: "Test instructions",
      model: "gpt-4",
      outputSchema: nil,
      events: [],
      output: { result: "test" },
      costDollars: 0.05,
      finishedAt: "2025-01-01T01:00:00Z",
      error: nil
    }

    stub_request(:get, "https://api.exa.ai/research/v1")
      .to_return(
        status: 200,
        body: { data: [task_data], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchList.new(@connection)
    result = service.call

    assert_equal 1, result.data.length
    assert_instance_of Exa::Resources::ResearchTask, result.data.first
    assert_equal "task123", result.data.first.research_id
    assert_equal "completed", result.data.first.status
  end

  def test_call_handles_has_more_true
    stub_request(:get, "https://api.exa.ai/research/v1")
      .to_return(
        status: 200,
        body: { data: [], hasMore: true, nextCursor: "next123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchList.new(@connection)
    result = service.call

    assert_equal true, result.has_more
  end

  def test_call_handles_has_more_false
    stub_request(:get, "https://api.exa.ai/research/v1")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchList.new(@connection)
    result = service.call

    assert_equal false, result.has_more
  end

  def test_call_handles_next_cursor_present
    stub_request(:get, "https://api.exa.ai/research/v1")
      .to_return(
        status: 200,
        body: { data: [], hasMore: true, nextCursor: "next123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchList.new(@connection)
    result = service.call

    assert_equal "next123", result.next_cursor
  end

  def test_call_handles_next_cursor_null
    stub_request(:get, "https://api.exa.ai/research/v1")
      .to_return(
        status: 200,
        body: { data: [], hasMore: false, nextCursor: nil }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchList.new(@connection)
    result = service.call

    assert_nil result.next_cursor
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:get, "https://api.exa.ai/research/v1")
      .to_return(
        status: 401,
        body: { error: "Unauthorized" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchList.new(@connection)

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end

  def test_call_raises_server_error_on_500
    stub_request(:get, "https://api.exa.ai/research/v1")
      .to_return(
        status: 500,
        body: { error: "Internal server error" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchList.new(@connection)

    assert_raises(Exa::InternalServerError) do
      service.call
    end
  end
end
