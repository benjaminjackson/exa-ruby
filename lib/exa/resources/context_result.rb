# frozen_string_literal: true

module Exa
  module Resources
    # Represents a Context API response from the Exa API
    #
    # This class wraps the JSON response from the /context endpoint and provides
    # a Ruby-friendly interface for accessing code snippets and metadata.
    class ContextResult < Struct.new(
      :request_id,
      :query,
      :response,
      :results_count,
      :cost_dollars,
      :search_time,
      :output_tokens,
      keyword_init: true
    )
      def initialize(**)
        super
        freeze
      end

      def to_h
        {
          request_id: request_id,
          query: query,
          response: response,
          results_count: results_count,
          cost_dollars: cost_dollars,
          search_time: search_time,
          output_tokens: output_tokens
        }
      end
    end
  end
end
