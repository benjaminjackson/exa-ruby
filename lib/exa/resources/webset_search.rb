# frozen_string_literal: true

module Exa
  module Resources
    # Represents a search operation within a webset
    #
    # A search finds entities matching specific criteria and can either
    # override existing webset items or append to them.
    class WebsetSearch < Struct.new(
      :id,
      :object,
      :status,
      :webset_id,
      :query,
      :entity,
      :criteria,
      :count,
      :behavior,
      :exclude,
      :scope,
      :progress,
      :recall,
      :metadata,
      :canceled_at,
      :canceled_reason,
      :created_at,
      :updated_at,
      keyword_init: true
    )
      def initialize(
        id:,
        object:,
        status:,
        webset_id: nil,
        query: nil,
        entity: nil,
        criteria: nil,
        count: nil,
        behavior: nil,
        exclude: nil,
        scope: nil,
        progress: nil,
        recall: nil,
        metadata: nil,
        canceled_at: nil,
        canceled_reason: nil,
        created_at: nil,
        updated_at: nil
      )
        super
        freeze
      end

      # Status helper methods
      def created?
        status == "created"
      end

      def running?
        status == "running"
      end

      def completed?
        status == "completed"
      end

      def failed?
        status == "failed"
      end

      def canceled?
        status == "canceled"
      end

      def in_progress?
        created? || running?
      end

      # Behavior helper methods
      def override?
        behavior == "override"
      end

      def append?
        behavior == "append"
      end

      def to_h
        {
          id: id,
          object: object,
          status: status,
          webset_id: webset_id,
          query: query,
          entity: entity,
          criteria: criteria,
          count: count,
          behavior: behavior,
          exclude: exclude,
          scope: scope,
          progress: progress,
          recall: recall,
          metadata: metadata,
          canceled_at: canceled_at,
          canceled_reason: canceled_reason,
          created_at: created_at,
          updated_at: updated_at
        }.compact
      end
    end
  end
end
