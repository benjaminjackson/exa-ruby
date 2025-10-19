module Exa
  module Resources
    # Represents a search response from the Exa API
    #
    # This class wraps the JSON response from the /search endpoint and provides
    # a Ruby-friendly interface for accessing search results and metadata.
    class SearchResult < Struct.new(
      :results,
      :request_id,
      :resolved_search_type,
      :search_type,
      :context,
      :cost_dollars,
      keyword_init: true
    )
      def initialize(results:, request_id: nil, resolved_search_type: nil, search_type: nil, context: nil, cost_dollars: nil)
        super
        freeze
      end

      def empty?
        results.empty?
      end

      def first
        results.first
      end
    end
  end
end
