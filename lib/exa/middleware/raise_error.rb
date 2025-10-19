# frozen_string_literal: true

require "faraday"

module Exa
  module Middleware
    class RaiseError < Faraday::Middleware
      def on_complete(env)
        case env[:status]
        when 400
          handle_error(env, Exa::BadRequest)
        when 401
          handle_error(env, Exa::Unauthorized)
        when 403
          handle_error(env, Exa::Forbidden)
        when 404
          handle_error(env, Exa::NotFound)
        when 422
          handle_error(env, Exa::UnprocessableEntity)
        when 429
          handle_error(env, Exa::TooManyRequests)
        when 500
          handle_error(env, Exa::InternalServerError)
        when 502
          handle_error(env, Exa::BadGateway)
        when 503
          handle_error(env, Exa::ServiceUnavailable)
        when 504
          handle_error(env, Exa::GatewayTimeout)
        end
      end

      private

      def handle_error(env, error_class)
        message = extract_error_message(env)
        raise error_class.new(message, env.response)
      end

      def extract_error_message(env)
        body = env[:body]

        if body.is_a?(Hash)
          return body["error"] if body["error"]
          return body[:error] if body[:error]
        end

        "HTTP #{env[:status]}"
      end
    end
  end
end

# Register the middleware with Faraday
Faraday::Response.register_middleware raise_error: Exa::Middleware::RaiseError
