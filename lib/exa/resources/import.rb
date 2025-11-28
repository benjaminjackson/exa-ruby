# frozen_string_literal: true

module Exa
  module Resources
    # Represents an import operation for bringing external data into Exa
    #
    # An import allows uploading CSV data containing entities (e.g., companies)
    # to be processed and enriched within the Exa system.
    class Import < Struct.new(
      :id,
      :object,
      :status,
      :format,
      :entity,
      :title,
      :count,
      :metadata,
      :failed_reason,
      :failed_at,
      :failed_message,
      :created_at,
      :updated_at,
      :upload_url,
      :upload_valid_until,
      keyword_init: true
    )
      def initialize(
        id:,
        object:,
        status:,
        format: nil,
        entity: nil,
        title: nil,
        count: nil,
        metadata: nil,
        failed_reason: nil,
        failed_at: nil,
        failed_message: nil,
        created_at: nil,
        updated_at: nil,
        upload_url: nil,
        upload_valid_until: nil
      )
        super
        freeze
      end

      # Status helper methods
      def pending?
        status == "pending"
      end

      def processing?
        status == "processing"
      end

      def completed?
        status == "completed"
      end

      def failed?
        status == "failed"
      end

      def to_h
        {
          id: id,
          object: object,
          status: status,
          format: format,
          entity: entity,
          title: title,
          count: count,
          metadata: metadata,
          failed_reason: failed_reason,
          failed_at: failed_at,
          failed_message: failed_message,
          created_at: created_at,
          updated_at: updated_at,
          upload_url: upload_url,
          upload_valid_until: upload_valid_until
        }.compact
      end
    end
  end
end
