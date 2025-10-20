# frozen_string_literal: true

require_relative "parameter_converter"

module Exa
  module Services
    class Search
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call
        response = @connection.post("/search", ParameterConverter.convert(@params))
        body = response.body

        Resources::SearchResult.new(
          results: body["results"],
          request_id: body["requestId"],
          resolved_search_type: body["resolvedSearchType"],
          search_type: body["searchType"],
          context: body["context"],
          cost_dollars: body["costDollars"]
        )
      end
    end
  end
end
