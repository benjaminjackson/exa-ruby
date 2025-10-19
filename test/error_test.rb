require "test_helper"

class ErrorTest < Minitest::Test
  def test_base_error_initialization_with_message
    error = Exa::Error.new("Something went wrong")

    assert_equal "Something went wrong", error.message
    assert_instance_of Exa::Error, error
    assert_kind_of StandardError, error
  end

  def test_error_initialization_with_message_and_response
    response = { status: 401, body: { error: "Unauthorized" } }
    error = Exa::Error.new("Bad token", response)

    assert_equal "Bad token", error.message
    assert_equal response, error.response
  end

  def test_client_error_inherits_from_error
    error = Exa::ClientError.new("Client error")

    assert_instance_of Exa::ClientError, error
    assert_kind_of Exa::Error, error
    assert_kind_of StandardError, error
  end

  def test_bad_request_inherits_from_client_error
    error = Exa::BadRequest.new("Bad request")

    assert_instance_of Exa::BadRequest, error
    assert_kind_of Exa::ClientError, error
    assert_kind_of Exa::Error, error
  end

  def test_unauthorized_inherits_from_client_error
    error = Exa::Unauthorized.new("Unauthorized")

    assert_instance_of Exa::Unauthorized, error
    assert_kind_of Exa::ClientError, error
    assert_kind_of Exa::Error, error
  end

  def test_forbidden_inherits_from_client_error
    error = Exa::Forbidden.new("Forbidden")

    assert_instance_of Exa::Forbidden, error
    assert_kind_of Exa::ClientError, error
    assert_kind_of Exa::Error, error
  end

  def test_not_found_inherits_from_client_error
    error = Exa::NotFound.new("Not found")

    assert_instance_of Exa::NotFound, error
    assert_kind_of Exa::ClientError, error
    assert_kind_of Exa::Error, error
  end

  def test_unprocessable_entity_inherits_from_client_error
    error = Exa::UnprocessableEntity.new("Unprocessable entity")

    assert_instance_of Exa::UnprocessableEntity, error
    assert_kind_of Exa::ClientError, error
    assert_kind_of Exa::Error, error
  end

  def test_too_many_requests_inherits_from_client_error
    error = Exa::TooManyRequests.new("Too many requests")

    assert_instance_of Exa::TooManyRequests, error
    assert_kind_of Exa::ClientError, error
    assert_kind_of Exa::Error, error
  end

  def test_server_error_inherits_from_error
    error = Exa::ServerError.new("Server error")

    assert_instance_of Exa::ServerError, error
    assert_kind_of Exa::Error, error
    assert_kind_of StandardError, error
  end

  def test_internal_server_error_inherits_from_server_error
    error = Exa::InternalServerError.new("Internal server error")

    assert_instance_of Exa::InternalServerError, error
    assert_kind_of Exa::ServerError, error
    assert_kind_of Exa::Error, error
  end

  def test_bad_gateway_inherits_from_server_error
    error = Exa::BadGateway.new("Bad gateway")

    assert_instance_of Exa::BadGateway, error
    assert_kind_of Exa::ServerError, error
    assert_kind_of Exa::Error, error
  end

  def test_service_unavailable_inherits_from_server_error
    error = Exa::ServiceUnavailable.new("Service unavailable")

    assert_instance_of Exa::ServiceUnavailable, error
    assert_kind_of Exa::ServerError, error
    assert_kind_of Exa::Error, error
  end

  def test_gateway_timeout_inherits_from_server_error
    error = Exa::GatewayTimeout.new("Gateway timeout")

    assert_instance_of Exa::GatewayTimeout, error
    assert_kind_of Exa::ServerError, error
    assert_kind_of Exa::Error, error
  end

  def test_configuration_error_inherits_from_error
    error = Exa::ConfigurationError.new("Configuration error")

    assert_instance_of Exa::ConfigurationError, error
    assert_kind_of Exa::Error, error
    assert_kind_of StandardError, error
  end
end
