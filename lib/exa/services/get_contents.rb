# frozen_string_literal: true

module Exa
  module Services
    class GetContents
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call
        response = @connection.post("/contents", @params)
        body = response.body

        results = body["results"]
        results = parse_json_summaries(results) if summary_schema?

        Resources::ContentsResult.new(
          results: results,
          request_id: body["requestId"],
          context: body["context"],
          statuses: body["statuses"],
          cost_dollars: body["costDollars"]
        )
      end

      private

      def summary_schema?
        @params[:summary].is_a?(Hash) && @params[:summary][:schema]
      end

      def parse_json_summaries(results)
        results&.map do |r|
          if r["summary"].is_a?(String)
            r.merge("summary" => JSON.parse(r["summary"]))
          else
            r
          end
        end
      end
    end
  end
end
