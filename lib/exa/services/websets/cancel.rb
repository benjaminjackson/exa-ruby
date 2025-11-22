# frozen_string_literal: true

module Exa
  module Services
    module Websets
      class Cancel
        def initialize(connection, id:)
          @connection = connection
          @id = id
        end

        def call
          response = @connection.post("/websets/v0/websets/#{@id}/cancel", {})
          body = response.body

          Resources::Webset.new(
            id: body["id"],
            object: body["object"],
            status: body["status"],
            external_id: body["externalId"],
            title: body["title"],
            searches: body["searches"],
            imports: body["imports"],
            enrichments: body["enrichments"],
            monitors: body["monitors"],
            excludes: body["excludes"],
            metadata: body["metadata"],
            created_at: body["createdAt"],
            updated_at: body["updatedAt"],
            items: body["items"]
          )
        end
      end
    end
  end
end
