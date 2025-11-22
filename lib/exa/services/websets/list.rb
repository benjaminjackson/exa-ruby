# frozen_string_literal: true

module Exa
  module Services
    module Websets
      class List
        def initialize(connection, **params)
          @connection = connection
          @params = params
        end

        def call
          response = @connection.get("/websets/v0/websets", @params)
          body = response.body

          Resources::WebsetCollection.new(
            data: body["data"],
            has_more: body["hasMore"],
            next_cursor: body["nextCursor"]
          )
        end
      end
    end
  end
end
