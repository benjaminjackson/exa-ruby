# frozen_string_literal: true

require_relative "parameter_converter"

module Exa
  module Services
    class Search
      VALID_SEARCH_TYPES = ["auto", "neural", "fast", "deep", "deep-reasoning", "instant"].freeze
      DEFAULT_SEARCH_TYPE = "auto"

      def initialize(connection, **params)
        @connection = connection
        @params = normalize_params(params)
        validate_search_type!
      end

      def call
        response = @connection.post("/search", ParameterConverter.convert(@params))
        body = response.body

        results = body["results"]
        results = parse_json_summaries(results) if summary_schema?

        Resources::SearchResult.new(
          results: results,
          request_id: body["requestId"],
          resolved_search_type: body["resolvedSearchType"],
          search_type: body["searchType"],
          context: body["context"],
          cost_dollars: body["costDollars"],
          output: body["output"]
        )
      end

      private

      def normalize_params(params)
        normalized = params.dup
        # Set default search type if not provided
        normalized[:type] = DEFAULT_SEARCH_TYPE unless normalized.key?(:type)
        normalized
      end

      def validate_search_type!
        search_type = @params[:type]
        return if VALID_SEARCH_TYPES.include?(search_type)

        raise ArgumentError, "Invalid search type: '#{search_type}'. Must be one of: #{VALID_SEARCH_TYPES.join(', ')}"
      end

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
