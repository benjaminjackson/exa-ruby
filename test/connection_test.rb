require "test_helper"

class ConnectionTest < Minitest::Test
  def test_build_returns_faraday_connection
    connection = Exa::Connection.build(api_key: "test_key")

    assert_instance_of Faraday::Connection, connection
  end

  def test_sets_api_key_header
    connection = Exa::Connection.build(api_key: "test_secret_key")

    # Make a test request to inspect headers
    stub_request(:get, "https://api.exa.ai/test")
      .with(headers: { "x-api-key" => "test_secret_key" })
      .to_return(status: 200, body: "")

    connection.get("/test")

    # If we reach here, the stub matched, meaning the header was set correctly
    assert true
  end

  def test_encodes_request_body_as_json
    connection = Exa::Connection.build(api_key: "test_key")

    stub_request(:post, "https://api.exa.ai/search")
      .with(
        body: '{"query":"test"}',
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(status: 200, body: '{"results":[]}')

    connection.post("/search", { query: "test" })

    # If we reach here, the stub matched, meaning JSON encoding worked
    assert true
  end

  def test_parses_response_body_as_json
    connection = Exa::Connection.build(api_key: "test_key")

    stub_request(:get, "https://api.exa.ai/data")
      .to_return(
        status: 200,
        body: '{"message":"success","count":42}',
        headers: { "Content-Type" => "application/json" }
      )

    response = connection.get("/data")

    assert_equal "success", response.body["message"]
    assert_equal 42, response.body["count"]
  end

  def test_sets_default_timeout
    connection = Exa::Connection.build(api_key: "test_key")

    assert_equal 30, connection.options.timeout
  end

  def test_allows_custom_timeout
    connection = Exa::Connection.build(api_key: "test_key", timeout: 60)

    assert_equal 60, connection.options.timeout
  end

  def test_sets_default_open_timeout
    connection = Exa::Connection.build(api_key: "test_key")

    assert_equal 10, connection.options.open_timeout
  end

  def test_allows_custom_open_timeout
    connection = Exa::Connection.build(api_key: "test_key", open_timeout: 20)

    assert_equal 20, connection.options.open_timeout
  end

  def test_allows_custom_adapter
    # Build connection with test adapter
    connection = Exa::Connection.build(api_key: "test_key", adapter: :test) do |stub|
      stub.get("/test") { |env| [200, {}, "test response"] }
    end

    # Make a request using the test adapter
    response = connection.get("/test")

    # Verify the test adapter was used (no WebMock stub needed)
    assert_equal 200, response.status
    assert_equal "test response", response.body
  end
end
