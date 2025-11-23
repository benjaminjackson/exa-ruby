module Exa
  module Resources
    # Represents a monitor run execution
    MonitorRun = Struct.new(
      :id,
      :object,
      :monitor_id,
      :status,
      :created_at,
      :updated_at,
      :completed_at,
      :failed_at,
      :failed_reason,
      keyword_init: true
    ) do
      def freeze
        super
        self
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

      def failed?
        status == "failed"
      end

      def to_h
        {
          id: id,
          object: object,
          monitor_id: monitor_id,
          status: status,
          created_at: created_at,
          updated_at: updated_at,
          completed_at: completed_at,
          failed_at: failed_at,
          failed_reason: failed_reason
        }.compact
      end
    end
  end
end
