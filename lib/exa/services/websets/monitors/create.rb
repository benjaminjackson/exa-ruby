# frozen_string_literal: true

module Exa
  module Services
    module Websets
      module Monitors
        class Create
          def initialize(connection, webset_id:, cadence:, behavior:, **params)
            @connection = connection
            @webset_id = webset_id
            @cadence = cadence
            @behavior = behavior
            @params = params
          end

          def call
            response = @connection.post(
              "/websets/v0/monitors",
              {
                websetId: @webset_id,
                cadence: @cadence,
                behavior: @behavior
              }.merge(@params)
            )
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
