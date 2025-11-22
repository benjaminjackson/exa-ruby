# frozen_string_literal: true

require_relative "create_validator"
require_relative "../websets_parameter_converter"

module Exa
  module Services
    module Websets
      class Create
        def initialize(connection, **params)
          @connection = connection
          @params = params
        end

        def call
          # Validate parameters before making the API call
          CreateValidator.validate!(@params)

          # Convert Ruby snake_case params to API camelCase
          converted_params = WebsetsParameterConverter.convert(@params)

          response = @connection.post("/websets/v0/websets", converted_params)
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
