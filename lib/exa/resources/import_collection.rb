# frozen_string_literal: true

module Exa
  module Resources
    # Represents a paginated list of imports from the Exa API
    #
    # This class wraps the JSON response from the GET /websets/v0/imports endpoint
    # and provides pagination support.
    class ImportCollection < Struct.new(
      :data,
      :has_more,
      :next_cursor,
      keyword_init: true
    )
      def initialize(data:, has_more: false, next_cursor: nil)
        super
        freeze
      end

      def empty?
        data.empty?
      end

      def to_h
        {
          data: data,
          has_more: has_more,
          next_cursor: next_cursor
        }
      end
    end
  end
end
