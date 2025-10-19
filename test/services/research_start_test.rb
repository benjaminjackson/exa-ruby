require "test_helper"

class ResearchStartTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
  end

  def test_initialize_with_connection_and_params
    service = Exa::Services::ResearchStart.new(@connection, instructions: "test instructions")

    assert_instance_of Exa::Services::ResearchStart, service
  end

  def test_call_posts_to_research_v1_endpoint
    stub_request(:post, "https://api.exa.ai/research/v1")
      .with(body: hash_including(instructions: "test instructions"))
      .to_return(
        status: 201,
        body: { researchId: "test123", createdAt: 1234567890, status: "pending", instructions: "test instructions" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchStart.new(@connection, instructions: "test instructions")
    service.call

    assert_requested :post, "https://api.exa.ai/research/v1"
  end

  def test_call_includes_instructions_parameter
    stub_request(:post, "https://api.exa.ai/research/v1")
      .with(body: hash_including(instructions: "What species of ant are similar to honeypot ants?"))
      .to_return(
        status: 201,
        body: { researchId: "test123", createdAt: 1234567890, status: "pending", instructions: "What species of ant are similar to honeypot ants?" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchStart.new(@connection, instructions: "What species of ant are similar to honeypot ants?")
    service.call

    assert_requested :post, "https://api.exa.ai/research/v1"
  end

  def test_call_includes_model_parameter
    stub_request(:post, "https://api.exa.ai/research/v1")
      .with(body: hash_including(instructions: "test", model: "exa-research-pro"))
      .to_return(
        status: 201,
        body: { researchId: "test123", createdAt: 1234567890, status: "pending", instructions: "test", model: "exa-research-pro" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchStart.new(@connection, instructions: "test", model: "exa-research-pro")
    service.call

    assert_requested :post, "https://api.exa.ai/research/v1"
  end

  def test_call_includes_output_schema_parameter
    output_schema = { type: "object", properties: { name: { type: "string" } } }
    stub_request(:post, "https://api.exa.ai/research/v1")
      .with(body: hash_including(instructions: "test", outputSchema: output_schema))
      .to_return(
        status: 201,
        body: { researchId: "test123", createdAt: 1234567890, status: "pending", instructions: "test", outputSchema: output_schema }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchStart.new(@connection, instructions: "test", outputSchema: output_schema)
    service.call

    assert_requested :post, "https://api.exa.ai/research/v1"
  end

  def test_call_returns_research_task_object
    stub_request(:post, "https://api.exa.ai/research/v1")
      .to_return(
        status: 201,
        body: {
          researchId: "123",
          createdAt: 1234567890,
          status: "pending",
          instructions: "test",
          model: "exa-research"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchStart.new(@connection, instructions: "test")
    result = service.call

    assert_instance_of Exa::Resources::ResearchTask, result
    assert_equal "123", result.research_id
    assert_equal 1234567890, result.created_at
    assert_equal "exa-research", result.model
  end

  def test_call_returns_task_with_pending_status
    stub_request(:post, "https://api.exa.ai/research/v1")
      .to_return(
        status: 201,
        body: {
          researchId: "123",
          createdAt: 1234567890,
          status: "pending",
          instructions: "test"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchStart.new(@connection, instructions: "test")
    result = service.call

    assert_equal "pending", result.status
    assert result.pending?
  end

  def test_call_returns_task_with_research_id
    stub_request(:post, "https://api.exa.ai/research/v1")
      .to_return(
        status: 201,
        body: {
          researchId: "unique-task-id-456",
          createdAt: 1234567890,
          status: "pending",
          instructions: "test"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchStart.new(@connection, instructions: "test")
    result = service.call

    assert_equal "unique-task-id-456", result.research_id
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:post, "https://api.exa.ai/research/v1")
      .to_return(
        status: 401,
        body: { error: "Invalid API key" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchStart.new(@connection, instructions: "test")

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end

  def test_call_raises_bad_request_on_400
    stub_request(:post, "https://api.exa.ai/research/v1")
      .to_return(
        status: 400,
        body: { error: "Bad request" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchStart.new(@connection, instructions: "test")

    assert_raises(Exa::BadRequest) do
      service.call
    end
  end

  def test_call_raises_server_error_on_500
    stub_request(:post, "https://api.exa.ai/research/v1")
      .to_return(
        status: 500,
        body: { error: "Internal server error" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::ResearchStart.new(@connection, instructions: "test")

    assert_raises(Exa::InternalServerError) do
      service.call
    end
  end
end
