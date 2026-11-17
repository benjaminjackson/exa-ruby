# frozen_string_literal: true

require_relative "../../resources/search_monitor_batch_result"

module Exa
  module Services
    module SearchMonitors
      # POST /monitors/batch — delete, pause or unpause every monitor that matches a filter.
      # The API uses snake_case keys here, so the body is built by hand and never converted.
      # It is a dry run unless the caller passes dry_run: false.
      class Batch
        def initialize(connection, action:, filter:, dry_run: true, limit: nil)
          @connection = connection
          @action = action
          @filter = filter
          @dry_run = dry_run
          @limit = limit
        end

        def call
          body = { action: @action, filter: @filter, dry_run: @dry_run != false }
          body[:limit] = @limit if @limit

          result = @connection.post("/monitors/batch", body).body
          Resources::SearchMonitorBatchResult.new(
            action: result["action"],
            affected: result["affected"],
            ids: result["ids"],
            dry_run: result["dry_run"],
            has_more: result["has_more"]
          )
        end
      end
    end
  end
end
