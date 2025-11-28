# frozen_string_literal: true

module Exa
  module Services
    module Websets
      module Monitors
        class Delete
          def initialize(connection, id:)
            @connection = connection
            @id = id
          end

          def call
            response = @connection.delete("/websets/v0/monitors/#{@id}")
            body = response.body

            Resources::Monitor.new(
              id: body["id"],
              object: body["object"],
              status: body["status"],
              webset_id: body["websetId"],
              cadence: body["cadence"],
              behavior: body["behavior"],
              created_at: body["createdAt"],
              updated_at: body["updatedAt"]
            )
          end
        end
      end
    end
  end
end
