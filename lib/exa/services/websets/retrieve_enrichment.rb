# frozen_string_literal: true

module Exa
  module Services
    module Websets
      class RetrieveEnrichment
        def initialize(connection, webset_id:, id:)
          @connection = connection
          @webset_id = webset_id
          @id = id
        end

        def call
          response = @connection.get("/websets/v0/websets/#{@webset_id}/enrichments/#{@id}")
          body = response.body

          Resources::WebsetEnrichment.new(
            id: body["id"],
            object: body["object"],
            status: body["status"],
            webset_id: body["websetId"],
            title: body["title"],
            description: body["description"],
            format: body["format"],
            options: body["options"],
            instructions: body["instructions"],
            metadata: body["metadata"],
            created_at: body["createdAt"],
            updated_at: body["updatedAt"]
          )
        end
      end
    end
  end
end
