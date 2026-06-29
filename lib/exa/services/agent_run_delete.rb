# frozen_string_literal: true

require_relative "../resources/agent_run"

module Exa
  module Services
    class AgentRunDelete
      def initialize(connection, run_id:)
        @connection = connection
        @run_id = run_id
      end

      def call
        response = @connection.delete("/agent/runs/#{@run_id}")
        body = response.body

        # ponytail: 204-vs-200 unconfirmed; nil-guarded. Confirm against live API.
        if body.nil? || body.empty?
          return Resources::AgentRun.new(id: @run_id, object: "agent_run", status: "deleted")
        end

        Resources::AgentRun.new(
          id: body["id"],
          object: body["object"],
          status: body["status"],
          stop_reason: body["stopReason"],
          created_at: body["createdAt"],
          completed_at: body["completedAt"],
          request: body["request"],
          output: body["output"],
          usage: body["usage"],
          cost_dollars: body["costDollars"]
        )
      end
    end
  end
end
