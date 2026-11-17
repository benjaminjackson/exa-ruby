# frozen_string_literal: true

require_relative "../resources/find_similar_result"

require_relative "parameter_converter"
require_relative "search"

module Exa
  module Services
    class FindSimilar
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call
        request_body = ParameterConverter.convert(@params)
        response = @connection.post("/findSimilar", request_body) do |request|
          request.headers.update(Search.beta_headers(request_body))
        end
        body = response.body

        Resources::FindSimilarResult.new(
          results: body["results"],
          request_id: body["requestId"],
          context: body["context"],
          cost_dollars: body["costDollars"],
          search_time: body["searchTime"]
        )
      end
    end
  end
end
