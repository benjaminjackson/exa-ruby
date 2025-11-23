# frozen_string_literal: true

module Exa
  module Services
    module Websets
      module Monitors
        class Update
          def initialize(connection, id:, **params)
            @connection = connection
            @id = id
            @params = params
          end

          def call
            response = @connection.patch("/websets/v0/monitors/#{@id}", @params)
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
