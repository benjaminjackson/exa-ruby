# frozen_string_literal: true

require_relative "../../resources/search_monitor"

module Exa
  module Services
    module SearchMonitors
      # GET /monitors/{id}
      class Get
        def initialize(connection, id:)
          @connection = connection
          @id = id
        end

        def call
          response = @connection.get("/monitors/#{@id}")
          Resources::SearchMonitor.from_response(response.body)
        end
      end
    end
  end
end
