# frozen_string_literal: true

module Exa
  module Services
    module Websets
      class ListItems
        def initialize(connection, webset_id:)
          @connection = connection
          @webset_id = webset_id
        end

        def call
          response = @connection.get("/websets/v0/websets/#{@webset_id}/items")
          body = response.body
          body["data"] || []
        end
      end
    end
  end
end
