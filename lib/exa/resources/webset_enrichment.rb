# frozen_string_literal: true

module Exa
  module Resources
    # Represents a webset enrichment from the Exa API
    #
    # An enrichment extracts specific data from web entities in a webset.
    class WebsetEnrichment < Struct.new(
      :id,
      :object,
      :status,
      :webset_id,
      :title,
      :description,
      :format,
      :options,
      :instructions,
      :metadata,
      :created_at,
      :updated_at,
      keyword_init: true
    )
      def initialize(
        id:,
        object:,
        status:,
        webset_id: nil,
        title: nil,
        description: nil,
        format: nil,
        options: nil,
        instructions: nil,
        metadata: nil,
        created_at: nil,
        updated_at: nil
      )
        super
        freeze
      end

      def pending?
        status == "pending"
      end

      def running?
        status == "running"
      end

      def completed?
        status == "completed"
      end

      def to_h
        {
          id: id,
          object: object,
          status: status,
          webset_id: webset_id,
          title: title,
          description: description,
          format: format,
          options: options,
          instructions: instructions,
          metadata: metadata,
          created_at: created_at,
          updated_at: updated_at
        }.compact
      end
    end
  end
end
