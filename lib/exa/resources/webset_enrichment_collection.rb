# frozen_string_literal: true

module Exa
  module Resources
    # Represents a list of enrichments for a webset from the Exa API
    #
    # This class wraps the JSON response from the GET /websets/v0/websets/{id}/enrichments endpoint
    class WebsetEnrichmentCollection < Struct.new(
      :data,
      keyword_init: true
    )
      def initialize(data:)
        super
        freeze
      end

      def empty?
        data.empty?
      end

      def to_h
        {
          data: data
        }
      end
    end
  end
end
