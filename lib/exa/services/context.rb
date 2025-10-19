# frozen_string_literal: true

module Exa
  module Services
    class Context
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call
        response = @connection.post("/context", @params)
        body = response.body

        Resources::ContextResult.new(
          request_id: body["requestId"],
          query: body["query"],
          response: body["response"],
          results_count: body["resultsCount"],
          cost_dollars: body["costDollars"],
          search_time: body["searchTime"],
          output_tokens: body["outputTokens"]
        )
      end
    end
  end
end
