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

        Resources::AgentRun.from_response(body)
      end
    end
  end
end
