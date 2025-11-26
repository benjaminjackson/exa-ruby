require "test_helper"

class RaiseErrorTest < Minitest::Test
  def test_raises_bad_request_on_400
    connection = Exa::Connection.build(api_key: "test_key")

    stub_request(:get, "https://api.exa.ai/test")
      .to_return(
        status: 400,
        body: '{"error":"Bad request"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Exa::BadRequest) do
      connection.get("/test")
    end

    assert_equal "Bad request", error.message
  end

  def test_raises_unauthorized_on_401
    connection = Exa::Connection.build(api_key: "test_key")

    stub_request(:get, "https://api.exa.ai/test")
      .to_return(
        status: 401,
        body: '{"error":"Invalid API key"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Exa::Unauthorized) do
      connection.get("/test")
    end

    assert_equal "Invalid API key", error.message
  end

  def test_raises_forbidden_on_403
    connection = Exa::Connection.build(api_key: "test_key")

    stub_request(:get, "https://api.exa.ai/test")
      .to_return(
        status: 403,
        body: '{"error":"Forbidden"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Exa::Forbidden) do
      connection.get("/test")
    end

    assert_equal "Forbidden", error.message
  end

  def test_raises_not_found_on_404
    connection = Exa::Connection.build(api_key: "test_key")

    stub_request(:get, "https://api.exa.ai/test")
      .to_return(
        status: 404,
        body: '{"error":"Not found"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Exa::NotFound) do
      connection.get("/test")
    end

    assert_equal "Not found", error.message
  end

  def test_raises_unprocessable_entity_on_422
    connection = Exa::Connection.build(api_key: "test_key")

    stub_request(:get, "https://api.exa.ai/test")
      .to_return(
        status: 422,
        body: '{"error":"Unprocessable entity"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Exa::UnprocessableEntity) do
      connection.get("/test")
    end

    assert_equal "Unprocessable entity", error.message
  end

  def test_raises_too_many_requests_on_429
    connection = Exa::Connection.build(api_key: "test_key")

    stub_request(:get, "https://api.exa.ai/test")
      .to_return(
        status: 429,
        body: '{"error":"Rate limit exceeded"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Exa::TooManyRequests) do
      connection.get("/test")
    end

    assert_equal "Rate limit exceeded", error.message
  end

  def test_raises_internal_server_error_on_500
    connection = Exa::Connection.build(api_key: "test_key")

    stub_request(:get, "https://api.exa.ai/test")
      .to_return(
        status: 500,
        body: '{"error":"Internal server error"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Exa::InternalServerError) do
      connection.get("/test")
    end

    assert_equal "Internal server error", error.message
  end

  def test_raises_bad_gateway_on_502
    connection = Exa::Connection.build(api_key: "test_key")

    stub_request(:get, "https://api.exa.ai/test")
      .to_return(
        status: 502,
        body: '{"error":"Bad gateway"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Exa::BadGateway) do
      connection.get("/test")
    end

    assert_equal "Bad gateway", error.message
  end

  def test_raises_service_unavailable_on_503
    connection = Exa::Connection.build(api_key: "test_key")

    stub_request(:get, "https://api.exa.ai/test")
      .to_return(
        status: 503,
        body: '{"error":"Service unavailable"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Exa::ServiceUnavailable) do
      connection.get("/test")
    end

    assert_equal "Service unavailable", error.message
  end

  def test_raises_gateway_timeout_on_504
    connection = Exa::Connection.build(api_key: "test_key")

    stub_request(:get, "https://api.exa.ai/test")
      .to_return(
        status: 504,
        body: '{"error":"Gateway timeout"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Exa::GatewayTimeout) do
      connection.get("/test")
    end

    assert_equal "Gateway timeout", error.message
  end

  def test_extracts_detailed_message_when_available
    connection = Exa::Connection.build(api_key: "test_key")

    stub_request(:get, "https://api.exa.ai/test")
      .to_return(
        status: 403,
        body: '{"statusCode":403,"timestamp":"2025-11-26T14:20:13.344Z","message":"Your team has reached the maximum number of concurrent requests","error":"Forbidden","path":"/v0/websets"}',
        headers: { "Content-Type" => "application/json" }
      )

    error = assert_raises(Exa::Forbidden) do
      connection.get("/test")
    end

    assert_equal "Your team has reached the maximum number of concurrent requests", error.message
  end
end
