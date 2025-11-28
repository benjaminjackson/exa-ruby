module Exa
  module Resources
    # Represents a webset monitor that automates updates on a schedule
    Monitor = Struct.new(
      :id,
      :object,
      :status,
      :webset_id,
      :cadence,
      :behavior,
      :created_at,
      :updated_at,
      keyword_init: true
    ) do
      def freeze
        super
        cadence.freeze if cadence
        behavior.freeze if behavior
        self
      end

      def pending?
        status == "pending"
      end

      def active?
        status == "active"
      end

      def paused?
        status == "paused"
      end

      def to_h
        {
          id: id,
          object: object,
          status: status,
          webset_id: webset_id,
          cadence: cadence,
          behavior: behavior,
          created_at: created_at,
          updated_at: updated_at
        }.compact
      end
    end
  end
end
