# frozen_string_literal: true

require "faraday"

module Exa
  module CLI
    # Faraday request middleware for --print-request. It writes the request
    # body to stderr as one line, then sends the request. It sits after
    # Faraday's :json middleware, so the body is the JSON string that goes
    # out on the wire. $stderr is read on each call, so a test that swaps
    # $stderr sees the output.
    class RequestPrinter < Faraday::Middleware
      # Print the encoded body, when the request has one, then pass the
      # request on to the rest of the stack.
      def call(env)
        $stderr.puts env.body if env.body
        @app.call(env)
      end
    end

    # Client that prints each request body with RequestPrinter. It lives in
    # the CLI namespace so that the printing is not part of the library's
    # Ruby API. Exa::Client itself does not change.
    class PrintingClient < Exa::Client
      private

      # Add RequestPrinter to the connection that Exa::Client builds. The
      # memo stops a second insert on later calls, and the insert happens
      # before the first request, while Faraday still lets the stack change.
      def connection
        @printing_connection ||= super.tap do |faraday_connection|
          faraday_connection.builder.insert_after(Faraday::Request::Json, RequestPrinter)
        end
      end
    end
  end
end
