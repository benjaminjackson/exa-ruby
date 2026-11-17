module Exa
  module Resources
    # One page of search monitors from GET /monitors.
    class SearchMonitorList < Struct.new(:data, :has_more, :next_cursor, keyword_init: true)
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
