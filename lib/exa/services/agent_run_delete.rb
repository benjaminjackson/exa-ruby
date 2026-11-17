# frozen_string_literal: true

require_relative "../resources/agent_run_deletion"

module Exa
  module Services
    class AgentRunDelete
      def initialize(connection, run_id:)
        @connection = connection
        @run_id = run_id
      end

      def call
        body = @connection.delete("/agent/runs/#{@run_id}").body

        Resources::AgentRunDeletion.new(
          id: body["id"],
          object: body["object"],
          deleted: body["deleted"]
        )
      end
    end
  end
end
