# frozen_string_literal: true

module Exa
  module Services
    module Websets
      class DeleteItem
        def initialize(connection, webset_id:, id:)
          @connection = connection
          @webset_id = webset_id
          @id = id
        end

        def call
          @connection.delete("/websets/v0/websets/#{@webset_id}/items/#{@id}")
          true
        end
      end
    end
  end
end
