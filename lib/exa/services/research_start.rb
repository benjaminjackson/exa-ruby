# frozen_string_literal: true

module Exa
  module Services
    class ResearchStart
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call
        response = @connection.post("/research/v1", @params)
        body = response.body

        Resources::ResearchTask.new(
          research_id: body["researchId"],
          created_at: body["createdAt"],
          status: body["status"],
          instructions: body["instructions"],
          model: body["model"],
          output_schema: body["outputSchema"]
        )
      end
    end
  end
end
