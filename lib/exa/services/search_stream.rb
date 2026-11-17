# frozen_string_literal: true

require_relative "answer_stream"
require_relative "parameter_converter"
require_relative "search"

module Exa
  module Services
    # Streams a /search request as server-sent events. The API streams only
    # when outputSchema is set, so this class requires output_schema. Each
    # chunk is yielded as a Hash with a "type" of text-delta, grounding,
    # results, stream-reset or done; an error chunk raises Exa::Error.
    class SearchStream < AnswerStream
      def initialize(connection, **params)
        raise ArgumentError, "output_schema is required for search streaming" unless params[:output_schema]

        params = { type: Search::DEFAULT_SEARCH_TYPE }.merge(params)
        validate_search_type!(params[:type])

        @connection = connection
        @params = ParameterConverter.convert(params.merge(stream: true))
      end

      private

      def path
        "/search"
      end

      def headers
        Search.beta_headers(@params)
      end

      def validate_search_type!(search_type)
        return if Search::VALID_SEARCH_TYPES.include?(search_type)

        raise ArgumentError, "Invalid search type: '#{search_type}'. Must be one of: #{Search::VALID_SEARCH_TYPES.join(', ')}"
      end
    end
  end
end
