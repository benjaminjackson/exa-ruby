# frozen_string_literal: true

module Exa
  module CLI
    class ErrorHandler
      def self.handle_error(error, command_name = nil)
        case error
        when ConfigurationError
          handle_configuration_error(error, command_name)
        when Unauthorized
          handle_unauthorized_error(error, command_name)
        when ClientError
          handle_client_error(error, command_name)
        when ServerError
          handle_server_error(error, command_name)
        else
          handle_generic_error(error, command_name)
        end
      end

      private

      def self.handle_configuration_error(error, command_name)
        $stderr.puts "❌ Configuration Error"
        $stderr.puts ""
        $stderr.puts error.message
        $stderr.puts ""
        $stderr.puts "Solutions:"
        $stderr.puts "  1. Set the EXA_API_KEY environment variable:"
        $stderr.puts "     export EXA_API_KEY='your-api-key'"
        $stderr.puts ""
        $stderr.puts "  2. Or pass it as a flag:"
        $stderr.puts "     #{command_name} ... --api-key YOUR_API_KEY" if command_name
        $stderr.puts ""
        $stderr.puts "Get your API key at: https://dashboard.exa.ai"
      end

      def self.handle_unauthorized_error(error, command_name)
        $stderr.puts "❌ Authentication Error"
        $stderr.puts ""
        $stderr.puts "Your API key is invalid or has expired."
        $stderr.puts ""
        if error.response&.fetch("error", nil)
          $stderr.puts "Details: #{error.response['error']}"
          $stderr.puts ""
        end
        $stderr.puts "Solutions:"
        $stderr.puts "  1. Verify your API key is correct"
        $stderr.puts "  2. Check if your API key has expired or been revoked"
        $stderr.puts "  3. Get a new key from: https://dashboard.exa.ai"
      end

      def self.handle_client_error(error, command_name)
        $stderr.puts "❌ Request Error"
        $stderr.puts ""
        $stderr.puts error.message
        $stderr.puts ""

        # Try to extract status code from response
        status = error.response&.fetch("status", "unknown") if error.response.is_a?(Hash)

        case status
        when 400
          $stderr.puts "This was a bad request. Please check your arguments."
        when 404
          $stderr.puts "The requested resource was not found."
        when 422
          $stderr.puts "The request data was invalid. Check your parameters."
        when 429
          $stderr.puts "You've exceeded the rate limit. Please wait before trying again."
        end

        $stderr.puts ""
        $stderr.puts "Run '#{command_name} --help' for usage information." if command_name
      end

      def self.handle_server_error(error, command_name)
        $stderr.puts "❌ Server Error"
        $stderr.puts ""
        $stderr.puts "The Exa API encountered an error:"
        $stderr.puts error.message
        $stderr.puts ""
        $stderr.puts "Solutions:"
        $stderr.puts "  1. Try again in a moment"
        $stderr.puts "  2. Check API status: https://status.exa.ai"
        $stderr.puts "  3. Contact support if the error persists"
      end

      def self.handle_generic_error(error, command_name)
        $stderr.puts "❌ Error"
        $stderr.puts ""
        $stderr.puts error.message
        $stderr.puts ""
        $stderr.puts "Run '#{command_name} --help' for usage information." if command_name
      end
    end
  end
end
