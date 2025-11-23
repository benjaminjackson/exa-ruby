# frozen_string_literal: true

require_relative "create_search_validator"

module Exa
  module Services
    module Websets
      class CreateSearch
        def initialize(connection, webset_id:, **params)
          @connection = connection
          @webset_id = webset_id
          @params = params
        end

        def call
          CreateSearchValidator.validate!(@params)

          response = @connection.post(
            "/websets/v0/websets/#{@webset_id}/searches",
            @params
          )
          body = response.body

          Resources::WebsetSearch.new(
            id: body["id"],
            object: body["object"],
            status: body["status"],
            webset_id: body["websetId"],
            query: body["query"],
            entity: body["entity"],
            criteria: body["criteria"],
            count: body["count"],
            behavior: body["behavior"],
            exclude: body["exclude"],
            scope: body["scope"],
            progress: body["progress"],
            recall: body["recall"],
            metadata: body["metadata"],
            canceled_at: body["canceledAt"],
            canceled_reason: body["canceledReason"],
            created_at: body["createdAt"],
            updated_at: body["updatedAt"]
          )
        end
      end
    end
  end
end
