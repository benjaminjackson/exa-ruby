# frozen_string_literal: true

require_relative "parameter_converter"
require_relative "../resources/agent_run"

module Exa
  module Services
    class AgentRunCreate
      def initialize(connection, query:, **params)
        @connection = connection
        @params = params.merge(query: query)
      end

      def call
        response = @connection.post("/agent/runs", ParameterConverter.convert(@params))
        body = response.body

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
