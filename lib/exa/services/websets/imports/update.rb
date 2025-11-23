# frozen_string_literal: true

module Exa
  module Services
    module Websets
      module Imports
        class Update
          def initialize(connection, id:, **params)
            @connection = connection
            @id = id
            @params = params
          end

          def call
            response = @connection.patch("/websets/v0/imports/#{@id}", @params)
            body = response.body

            Resources::Import.new(
              id: body["id"],
              object: body["object"],
              status: body["status"],
              format: body["format"],
              entity: body["entity"],
              title: body["title"],
              count: body["count"],
              metadata: body["metadata"],
              failed_reason: body["failedReason"],
              failed_at: body["failedAt"],
              failed_message: body["failedMessage"],
              created_at: body["createdAt"],
              updated_at: body["updatedAt"],
              upload_url: body["uploadUrl"],
              upload_valid_until: body["uploadValidUntil"]
            )
          end
        end
      end
    end
  end
end
