module Exa
  module Services
    class ResearchGet
      def initialize(connection, research_id:, **params)
        @connection = connection
        @research_id = research_id
        @params = params
      end

      def call
        response = @connection.get("/research/v1/#{@research_id}", @params)
        body = response.body

        Resources::ResearchTask.new(
          research_id: body["researchId"],
          created_at: body["createdAt"],
          status: body["status"],
          instructions: body["instructions"],
          model: body["model"],
          output_schema: body["outputSchema"],
          events: body["events"],
          output: body["output"],
          cost_dollars: body["costDollars"],
          finished_at: body["finishedAt"],
          error: body["error"]
        )
      end
    end
  end
end
