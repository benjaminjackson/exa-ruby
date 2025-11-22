# frozen_string_literal: true

module Exa
  module Resources
    # Represents a webset from the Exa API
    #
    # A webset is a collection of web entities (companies, people, etc.)
    # discovered through searches, imports, and enrichments.
    class Webset < Struct.new(
      :id,
      :object,
      :status,
      :external_id,
      :title,
      :searches,
      :imports,
      :enrichments,
      :monitors,
      :excludes,
      :metadata,
      :created_at,
      :updated_at,
      :items,
      keyword_init: true
    )
      def initialize(
        id:,
        object:,
        status:,
        external_id: nil,
        title: nil,
        searches: nil,
        imports: nil,
        enrichments: nil,
        monitors: nil,
        excludes: nil,
        metadata: nil,
        created_at: nil,
        updated_at: nil,
        items: nil
      )
        super
        freeze
      end

      def idle?
        status == "idle"
      end

      def processing?
        status == "processing"
      end

      def to_h
        {
          id: id,
          object: object,
          status: status,
          external_id: external_id,
          title: title,
          searches: searches,
          imports: imports,
          enrichments: enrichments,
          monitors: monitors,
          excludes: excludes,
          metadata: metadata,
          created_at: created_at,
          updated_at: updated_at,
          items: items
        }.compact
      end
    end
  end
end
