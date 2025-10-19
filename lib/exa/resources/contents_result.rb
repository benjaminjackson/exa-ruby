module Exa
  module Resources
    # Represents a contents response from the Exa API
    #
    # This class wraps the JSON response from the /contents endpoint and provides
    # a Ruby-friendly interface for accessing content results and metadata.
    class ContentsResult < Struct.new(
      :results,
      :request_id,
      :context,
      :statuses,
      :cost_dollars,
      keyword_init: true
    )
      def initialize(results:, request_id: nil, context: nil, statuses: nil, cost_dollars: nil)
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
