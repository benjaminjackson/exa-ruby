# frozen_string_literal: true

module Exa
  module Services
    module Websets
      class ListItems
        def initialize(connection, webset_id:, **params)
          @connection = connection
          @webset_id = webset_id
          @params = params
        end

        def call
          response = @connection.get("/websets/v0/websets/#{@webset_id}/items", @params)
          body = response.body

          Resources::WebsetItemCollection.new(
            data: body["data"] || [],
            has_more: body["hasMore"] || false,
            next_cursor: body["nextCursor"]
          )
        end
      end
    end
  end
end
