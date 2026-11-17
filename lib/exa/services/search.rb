# frozen_string_literal: true

require_relative "parameter_converter"

module Exa
  module Services
    class Search
      VALID_SEARCH_TYPES = ["auto", "lite", "deep-lite", "neural", "fast", "deep", "deep-reasoning", "instant"].freeze
      DEFAULT_SEARCH_TYPE = "auto"
      DYNAMIC_HIGHLIGHTS_BETA = "dynamic-highlights-2026-08-28"
      BETA_HIGHLIGHTS_KEYS = %w[dynamic verbosity].freeze

      # Returns the Exa-Beta header that a converted request body needs, or an
      # empty hash. The API rejects highlights.dynamic and highlights.verbosity
      # without it. Highlights sit under contents on /search and /findSimilar
      # and at the top level on /contents, so both places are checked.
      def self.beta_headers(body)
        contents = body[:contents] || body["contents"]
        highlights = contents[:highlights] || contents["highlights"] if contents.is_a?(Hash)
        highlights ||= body[:highlights] || body["highlights"]
        return {} unless highlights.is_a?(Hash)
        return {} unless highlights.keys.any? { |key| BETA_HIGHLIGHTS_KEYS.include?(key.to_s) }

        { "Exa-Beta" => DYNAMIC_HIGHLIGHTS_BETA }
      end

      # Raises ArgumentError unless search_type is one of VALID_SEARCH_TYPES.
      def self.validate_search_type!(search_type)
        return if VALID_SEARCH_TYPES.include?(search_type)

        raise ArgumentError, "Invalid search type: '#{search_type}'. Must be one of: #{VALID_SEARCH_TYPES.join(', ')}"
      end

      def initialize(connection, **params)
        @connection = connection
        @params = normalize_params(params)
        validate_search_type!
      end

      def call
        request_body = ParameterConverter.convert(@params)
        response = @connection.post("/search", request_body) do |request|
          request.headers.update(self.class.beta_headers(request_body))
        end
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
          output: body["output"],
          warnings: body["warnings"],
          notices: body["notices"],
          search_time: body["searchTime"]
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
        self.class.validate_search_type!(@params[:type])
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
