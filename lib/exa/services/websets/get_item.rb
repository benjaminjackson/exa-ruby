# frozen_string_literal: true

module Exa
  module Services
    module Websets
      class GetItem
        def initialize(connection, webset_id:, id:)
          @connection = connection
          @webset_id = webset_id
          @id = id
        end

        def call
          response = @connection.get("/websets/v0/websets/#{@webset_id}/items/#{@id}")
          response.body
        end
      end
    end
  end
end
