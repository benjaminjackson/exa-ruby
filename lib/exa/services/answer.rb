# frozen_string_literal: true

module Exa
  module Services
    class Answer
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call
        response = @connection.post("/answer", @params)
        body = response.body

        Resources::Answer.new(
          answer: body["answer"],
          citations: body["citations"] || [],
          cost_dollars: body["costDollars"]
        )
      end
    end
  end
end
