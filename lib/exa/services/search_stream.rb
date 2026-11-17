# frozen_string_literal: true

require_relative "answer_stream"
require_relative "search"

module Exa
  module Services
    # Streams a /search request as server-sent events. The API streams only
    # when outputSchema is set, so this class requires output_schema. Each
    # chunk is yielded as a Hash with a "type" of text-delta, grounding,
    # results, stream-reset or done; an error chunk raises Exa::Error.
    class SearchStream < AnswerStream
      # Checks output_schema and the search type, then converts the params
      # into the /search request body with stream set to true.
      def initialize(connection, **params)
        raise ArgumentError, "output_schema is required for search streaming" unless params[:output_schema]

        params = { type: Search::DEFAULT_SEARCH_TYPE }.merge(params)
        Search.validate_search_type!(params[:type])

        @connection = connection
        @params = ParameterConverter.convert(params.merge(stream: true))
      end

      private

      # Streams post to /search instead of /answer.
      def path
        "/search"
      end

      # Sends the Exa-Beta header when the body asks for dynamic highlights.
      def headers
        Search.beta_headers(@params)
      end
    end
  end
end
