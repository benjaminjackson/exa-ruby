module Exa
  module Resources
    # Result of DELETE /agent/runs/{id}: {id, object: "agent_run.deleted", deleted: true}.
    class AgentRunDeletion < Struct.new(:id, :object, :deleted, keyword_init: true)
      def initialize(id:, object: "agent_run.deleted", deleted: true)
        super
        freeze
      end

      def deleted? = deleted == true

      def to_h
        { id: id, object: object, deleted: deleted }
      end
    end
  end
end
