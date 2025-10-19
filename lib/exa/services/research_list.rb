module Exa
  module Services
    class ResearchList
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call
        response = @connection.get("/research/v1", @params)
        body = response.body

        data = body["data"].map do |task_data|
          Resources::ResearchTask.new(
            research_id: task_data["researchId"],
            created_at: task_data["createdAt"],
            status: task_data["status"],
            instructions: task_data["instructions"],
            model: task_data["model"],
            output_schema: task_data["outputSchema"],
            events: task_data["events"],
            output: task_data["output"],
            cost_dollars: task_data["costDollars"],
            finished_at: task_data["finishedAt"],
            error: task_data["error"]
          )
        end

        Resources::ResearchList.new(
          data: data,
          has_more: body["hasMore"],
          next_cursor: body["nextCursor"]
        )
      end
    end
  end
end
