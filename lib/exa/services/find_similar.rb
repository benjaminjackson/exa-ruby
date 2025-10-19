# frozen_string_literal: true

require_relative "../resources/find_similar_result"

module Exa
  module Services
    class FindSimilar
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call
        response = @connection.post("/findSimilar", @params)
        body = response.body

        Resources::FindSimilarResult.new(
          results: body["results"],
          request_id: body["requestId"],
          context: body["context"],
          cost_dollars: body["costDollars"]
        )
      end
    end
  end
end
