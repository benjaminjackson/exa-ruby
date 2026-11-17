# frozen_string_literal: true

require_relative "../parameter_converter"
require_relative "../../resources/search_monitor"

module Exa
  module Services
    module SearchMonitors
      # POST /monitors — create a scheduled search that posts results to a webhook.
      class Create
        def initialize(connection, search:, webhook:, **params)
          @connection = connection
          @params = params.merge(search: search, webhook: webhook)
        end

        def call
          response = @connection.post("/monitors", request_body)
          Resources::SearchMonitor.from_response(response.body)
        end

        private

        # Only the search hash and the top-level output_schema key change case.
        # Values of metadata and output_schema go to the API as given.
        def request_body
          @params.each_with_object({}) do |(key, value), body|
            case key
            when :search then body[:search] = ParameterConverter.convert(value)
            when :output_schema then body[:outputSchema] = value
            else body[key] = value
            end
          end
        end
      end
    end
  end
end
