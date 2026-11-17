# frozen_string_literal: true

require_relative "../resources/agent_run"

module Exa
  module Services
    # Ends a run early and keeps the results gathered so far. The spec gives
    # this endpoint no request body, so none is sent.
    class AgentRunStop
      def initialize(connection, run_id:)
        @connection = connection
        @run_id = run_id
      end

      def call
        response = @connection.post("/agent/runs/#{@run_id}/stop")
        Resources::AgentRun.from_response(response.body)
      end
    end
  end
end
