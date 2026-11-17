module Exa
  module Resources
    # One run of a search monitor (/monitors/{id}/runs).
    class SearchMonitorRun < Struct.new(
      :id, :monitor_id, :status, :output, :fail_reason, :started_at, :completed_at,
      :failed_at, :cancelled_at, :duration_ms, :created_at, :updated_at,
      keyword_init: true
    )
      def initialize(id:, monitor_id: nil, status: nil, output: nil, fail_reason: nil, started_at: nil, completed_at: nil,
                     failed_at: nil, cancelled_at: nil, duration_ms: nil, created_at: nil, updated_at: nil)
        super
        freeze
      end

      # Build from a raw API response body (camelCase keys).
      def self.from_response(body)
        new(
          id: body["id"],
          monitor_id: body["monitorId"],
          status: body["status"],
          output: body["output"],
          fail_reason: body["failReason"],
          started_at: body["startedAt"],
          completed_at: body["completedAt"],
          failed_at: body["failedAt"],
          cancelled_at: body["cancelledAt"],
          duration_ms: body["durationMs"],
          created_at: body["createdAt"],
          updated_at: body["updatedAt"]
        )
      end

      def pending?   = status == "pending"
      def running?   = status == "running"
      def completed? = status == "completed"
      def failed?    = status == "failed"
      def cancelled? = status == "cancelled"

      def finished? = completed? || failed? || cancelled?

      def to_h
        super.compact
      end
    end
  end
end
