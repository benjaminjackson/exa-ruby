# frozen_string_literal: true

require_relative "../resources/agent_run"
require_relative "../resources/agent_run_list"

module Exa
  module Services
    class AgentRunList
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call
        response = @connection.get("/agent/runs", @params)
        body = response.body

        data = body["data"].map do |run_data|
          Resources::AgentRun.new(
            id: run_data["id"],
            object: run_data["object"],
            status: run_data["status"],
            stop_reason: run_data["stopReason"],
            created_at: run_data["createdAt"],
            completed_at: run_data["completedAt"],
            request: run_data["request"],
            output: run_data["output"],
            usage: run_data["usage"],
            cost_dollars: run_data["costDollars"]
          )
        end

        Resources::AgentRunList.new(
          data: data,
          has_more: body["hasMore"],
          next_cursor: body["nextCursor"]
        )
      end
    end
  end
end
