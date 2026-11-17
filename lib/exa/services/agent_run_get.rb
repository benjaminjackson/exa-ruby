# frozen_string_literal: true

require_relative "../resources/agent_run"

module Exa
  module Services
    class AgentRunGet
      def initialize(connection, run_id:, **params)
        @connection = connection
        @run_id = run_id
        @params = params
      end

      def call
        response = @connection.get("/agent/runs/#{@run_id}", @params)
        body = response.body

        Resources::AgentRun.from_response(body)
      end
    end
  end
end
