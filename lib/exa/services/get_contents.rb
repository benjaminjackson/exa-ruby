# frozen_string_literal: true

module Exa
  module Services
    class GetContents
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call
        response = @connection.post("/contents", @params)
        body = response.body

        Resources::ContentsResult.new(
          results: body["results"],
          request_id: body["requestId"],
          context: body["context"],
          statuses: body["statuses"],
          cost_dollars: body["costDollars"]
        )
      end
    end
  end
end
