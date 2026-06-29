# frozen_string_literal: true

require_relative "../resources/agent_run_event_list"

module Exa
  module Services
    class AgentRunEvents
      def initialize(connection, run_id:, **params)
        @connection = connection
        @run_id = run_id
        @params = params
      end

      def call
        response = @connection.get("/agent/runs/#{@run_id}/events", @params)
        body = response.body

        # Confirmed live: GET /agent/runs/{id}/events returns a paginated list
        # {object: "list", data: [...], hasMore, nextCursor}.
        Resources::AgentRunEventList.new(
          data: body["data"] || [],
          has_more: body["hasMore"],
          next_cursor: body["nextCursor"]
        )
      end
    end
  end
end
