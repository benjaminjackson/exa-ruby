# frozen_string_literal: true

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
        # ponytail: events response shape unconfirmed; returning parsed body verbatim. Wrap in a collection if it paginates. Confirm against live API.
        response.body
      end
    end
  end
end
