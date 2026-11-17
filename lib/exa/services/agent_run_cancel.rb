# frozen_string_literal: true

require_relative "../resources/agent_run"

module Exa
  module Services
    class AgentRunCancel
      def initialize(connection, run_id:)
        @connection = connection
        @run_id = run_id
      end

      def call
        response = @connection.post("/agent/runs/#{@run_id}/cancel", {})
        body = response.body

        Resources::AgentRun.from_response(body)
      end
    end
  end
end
