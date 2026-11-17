module Exa
  module Resources
    # A scheduled Exa search that sends new results to a webhook (/monitors).
    # Not the same as Monitor, which belongs to Websets.
    class SearchMonitor < Struct.new(
      :id, :name, :status, :search, :trigger, :webhook, :output_schema,
      :metadata, :next_run_at, :created_at, :updated_at, :webhook_secret,
      keyword_init: true
    )
      def initialize(id:, name: nil, status: nil, search: nil, trigger: nil, webhook: nil, output_schema: nil,
                     metadata: nil, next_run_at: nil, created_at: nil, updated_at: nil, webhook_secret: nil)
        super
        freeze
      end

      # Build from a raw API response body (camelCase keys).
      def self.from_response(body)
        new(
          id: body["id"],
          name: body["name"],
          status: body["status"],
          search: body["search"],
          trigger: body["trigger"],
          webhook: body["webhook"],
          output_schema: body["outputSchema"],
          metadata: body["metadata"],
          next_run_at: body["nextRunAt"],
          created_at: body["createdAt"],
          updated_at: body["updatedAt"],
          webhook_secret: body["webhookSecret"]
        )
      end

      def active?   = status == "active"
      def paused?   = status == "paused"
      def disabled? = status == "disabled"

      def to_h
        super.compact
      end
    end
  end
end
