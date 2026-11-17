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
          Resources::AgentRun.from_response(run_data)
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
