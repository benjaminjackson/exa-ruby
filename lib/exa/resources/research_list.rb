module Exa
  module Resources
    class ResearchList < Struct.new(:data, :has_more, :next_cursor, keyword_init: true)
      def initialize(data:, has_more:, next_cursor: nil)
        super
        freeze
      end

      def to_h
        {
          data: data.map { |item| item.respond_to?(:to_h) ? item.to_h : item },
          has_more: has_more,
          next_cursor: next_cursor
        }
      end
    end
  end
end
