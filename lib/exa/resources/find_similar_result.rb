module Exa
  module Resources
    # Represents a find similar response from the Exa API
    #
    # This class wraps the JSON response from the /findSimilar endpoint and provides
    # a Ruby-friendly interface for accessing similar results and metadata.
    class FindSimilarResult < Struct.new(
      :results,
      :request_id,
      :context,
      :cost_dollars,
      keyword_init: true
    )
      def initialize(results:, request_id: nil, context: nil, cost_dollars: nil)
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
