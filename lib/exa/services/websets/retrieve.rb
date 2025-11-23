# frozen_string_literal: true

module Exa
  module Services
    module Websets
      class Retrieve
        def initialize(connection, id:, **params)
          @connection = connection
          @id = id
          @params = normalize_params(params)
        end

        def call
          response = @connection.get("/websets/v0/websets/#{@id}", @params)
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

        private

        def normalize_params(params)
          # Convert expand array to comma-separated string for API compatibility
          if params[:expand].is_a?(Array)
            params[:expand] = params[:expand].join(",")
          end
          params
        end
      end
    end
  end
end
