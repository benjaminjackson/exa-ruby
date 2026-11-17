# frozen_string_literal: true

require_relative "parameter_converter"
require_relative "search"

module Exa
  module Services
    class GetContents
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call
        request_body = ParameterConverter.convert_contents(@params)
        response = @connection.post("/contents", request_body) do |request|
          request.headers.update(Search.beta_headers(request_body))
        end
        body = response.body

        results = body["results"]
        results = Search.parse_json_summaries(results) if summary_schema?(request_body)

        Resources::ContentsResult.new(
          results: results,
          request_id: body["requestId"],
          context: body["context"],
          statuses: body["statuses"],
          cost_dollars: body["costDollars"],
          search_time: body["searchTime"]
        )
      end

      private

      # True when the request asked for JSON summaries. Reads the converted
      # body, so a flat summary_schema: counts as well as summary: {schema:}.
      def summary_schema?(request_body)
        request_body[:summary].is_a?(Hash) && request_body[:summary][:schema]
      end
    end
  end
end
