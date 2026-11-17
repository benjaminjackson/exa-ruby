module Exa
  module Resources
    # One page of search monitor runs from GET /monitors/{id}/runs.
    class SearchMonitorRunList < Struct.new(:data, :has_more, :next_cursor, keyword_init: true)
      def initialize(data:, has_more:, next_cursor: nil)
        super
        freeze
      end

      def to_h
        {
          data: data.map(&:to_h),
          has_more: has_more,
          next_cursor: next_cursor
        }
      end
    end
  end
end
