# frozen_string_literal: true

module Exa
  class Error < StandardError
    attr_reader :response

    def initialize(message = nil, response = nil)
      @response = response
      super(message)
    end
  end

  # Client errors (4xx)
  class ClientError < Error; end
  class BadRequest < ClientError; end          # 400
  class Unauthorized < ClientError; end        # 401
  class Forbidden < ClientError; end           # 403
  class NotFound < ClientError; end            # 404
  class UnprocessableEntity < ClientError; end # 422
  class TooManyRequests < ClientError; end     # 429

  # Server errors (5xx)
  class ServerError < Error; end
  class InternalServerError < ServerError; end # 500
  class BadGateway < ServerError; end          # 502
  class ServiceUnavailable < ServerError; end  # 503
  class GatewayTimeout < ServerError; end      # 504

  # Configuration errors
  class ConfigurationError < Error; end
end
