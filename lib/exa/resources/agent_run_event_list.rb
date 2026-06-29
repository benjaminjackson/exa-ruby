module Exa
  module Resources
    # Paginated collection of agent run events.
    # Mirrors AgentRunList's data/has_more/next_cursor shape; event items are
    # kept as plain hashes (the API returns {id, event, data, createdAt} per event).
    class AgentRunEventList < Struct.new(:data, :has_more, :next_cursor, keyword_init: true)
      def initialize(data:, has_more: false, next_cursor: nil)
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
