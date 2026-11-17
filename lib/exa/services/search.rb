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

      # Parses each result whose summary is a String of JSON into a Hash. The
      # API returns a summary as JSON text when the request gave a schema.
      # A summary that is not valid JSON, an empty one included, is kept as
      # received, so one bad summary does not lose the other results.
      # GetContents uses it too.
      def self.parse_json_summaries(results)
        results&.map do |r|
          next r unless r["summary"].is_a?(String)

          begin
            r.merge("summary" => JSON.parse(r["summary"]))
          rescue JSON::ParserError
            r
          end
        end
      end

      # on_request, when given, is called with the converted request body
      # just before it is sent. It is a keyword of its own so it never
      # reaches the body.
      def initialize(connection, on_request: nil, **params)
        @connection = connection
        @on_request = on_request
        @params = normalize_params(params)
        validate_search_type!
      end

      def call
        request_body = ParameterConverter.convert(@params)
        @on_request&.call(request_body)
        response = @connection.post("/search", request_body) do |request|
          request.headers.update(self.class.beta_headers(request_body))
        end
        body = response.body

        results = body["results"]
        results = self.class.parse_json_summaries(results) if summary_schema?(request_body)

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

      # True when the request asked for JSON summaries. Reads the converted
      # body, so a flat summary_schema: and a caller's contents: {summary:
      # {schema:}} count as well as summary: {schema:}.
      def summary_schema?(request_body)
        contents = request_body[:contents]
        return false unless contents.is_a?(Hash)

        contents[:summary].is_a?(Hash) && contents[:summary][:schema]
      end
    end
  end
end
