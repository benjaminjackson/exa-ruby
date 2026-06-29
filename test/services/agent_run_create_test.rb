require "test_helper"
require_relative "../../lib/exa/services/agent_run_create"

class AgentRunCreateTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
  end

  def test_initialize_with_connection_and_params
    service = Exa::Services::AgentRunCreate.new(@connection, query: "Find AI startups in NYC")

    assert_instance_of Exa::Services::AgentRunCreate, service
  end

  def test_call_posts_to_agent_runs_endpoint
    stub_request(:post, "https://api.exa.ai/agent/runs")
      .with(body: hash_including(query: "Find AI startups in NYC"))
      .to_return(
        status: 200,
        body: { id: "run_abc123", object: "agent_run", status: "queued" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCreate.new(@connection, query: "Find AI startups in NYC")
    service.call

    assert_requested :post, "https://api.exa.ai/agent/runs"
  end

  def test_call_includes_query_parameter
    stub_request(:post, "https://api.exa.ai/agent/runs")
      .with(body: hash_including(query: "Identify Series B biotech companies founded after 2020"))
      .to_return(
        status: 200,
        body: { id: "run_abc123", object: "agent_run", status: "queued" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCreate.new(@connection, query: "Identify Series B biotech companies founded after 2020")
    service.call

    assert_requested :post, "https://api.exa.ai/agent/runs"
  end

  def test_call_converts_system_prompt_to_camel_case
    stub_request(:post, "https://api.exa.ai/agent/runs")
      .with(body: hash_including(systemPrompt: "You are a research assistant"))
      .to_return(
        status: 200,
        body: { id: "run_abc123", object: "agent_run", status: "queued" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCreate.new(@connection, query: "Find climate tech companies", system_prompt: "You are a research assistant")
    service.call

    assert_requested :post, "https://api.exa.ai/agent/runs"
  end

  def test_call_converts_output_schema_to_camel_case
    output_schema = { type: "object", properties: { name: { type: "string" } } }
    stub_request(:post, "https://api.exa.ai/agent/runs")
      .with(body: hash_including(outputSchema: output_schema))
      .to_return(
        status: 200,
        body: { id: "run_abc123", object: "agent_run", status: "queued" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCreate.new(@connection, query: "Find fintech startups", output_schema: output_schema)
    service.call

    assert_requested :post, "https://api.exa.ai/agent/runs"
  end

  def test_call_converts_previous_run_id_to_camel_case
    stub_request(:post, "https://api.exa.ai/agent/runs")
      .with(body: hash_including(previousRunId: "run_xyz789"))
      .to_return(
        status: 200,
        body: { id: "run_abc123", object: "agent_run", status: "queued" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCreate.new(@connection, query: "Refine results", previous_run_id: "run_xyz789")
    service.call

    assert_requested :post, "https://api.exa.ai/agent/runs"
  end

  def test_call_converts_data_sources_to_camel_case
    data_sources = [{ type: "web" }]
    stub_request(:post, "https://api.exa.ai/agent/runs")
      .with(body: hash_including(dataSources: data_sources))
      .to_return(
        status: 200,
        body: { id: "run_abc123", object: "agent_run", status: "queued" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCreate.new(@connection, query: "Find SaaS companies", data_sources: data_sources)
    service.call

    assert_requested :post, "https://api.exa.ai/agent/runs"
  end

  def test_call_returns_agent_run_object
    stub_request(:post, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 200,
        body: {
          id: "run_abc123",
          object: "agent_run",
          status: "queued",
          createdAt: 1234567890
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCreate.new(@connection, query: "Find enterprise SaaS companies with $10M+ ARR")
    result = service.call

    assert_instance_of Exa::Resources::AgentRun, result
    assert_equal "run_abc123", result.id
    assert_equal "agent_run", result.object
    assert_equal "queued", result.status
    assert_equal 1234567890, result.created_at
  end

  def test_call_returns_queued_status
    stub_request(:post, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 200,
        body: { id: "run_abc123", object: "agent_run", status: "queued" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCreate.new(@connection, query: "Find logistics startups with recent funding")
    result = service.call

    assert_equal "queued", result.status
    assert result.queued?
  end

  def test_call_raises_unauthorized_on_401
    stub_request(:post, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 401,
        body: { error: "Invalid API key" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCreate.new(@connection, query: "Find AI companies")

    assert_raises(Exa::Unauthorized) do
      service.call
    end
  end

  def test_call_raises_payment_required_on_402
    stub_request(:post, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 402,
        body: { error: "Payment required" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCreate.new(@connection, query: "Find AI companies")

    assert_raises(Exa::PaymentRequired) do
      service.call
    end
  end

  def test_call_raises_too_many_requests_on_429
    stub_request(:post, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 429,
        body: { error: "Rate limit exceeded" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCreate.new(@connection, query: "Find AI companies")

    assert_raises(Exa::TooManyRequests) do
      service.call
    end
  end

  def test_call_raises_server_error_on_500
    stub_request(:post, "https://api.exa.ai/agent/runs")
      .to_return(
        status: 500,
        body: { error: "Internal server error" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Exa::Services::AgentRunCreate.new(@connection, query: "Find AI companies")

    assert_raises(Exa::InternalServerError) do
      service.call
    end
  end
end
