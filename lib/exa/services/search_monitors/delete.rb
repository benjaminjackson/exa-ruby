# frozen_string_literal: true

require_relative "../../resources/search_monitor"

module Exa
  module Services
    module SearchMonitors
      # DELETE /monitors/{id} — returns the deleted monitor.
      class Delete
        def initialize(connection, id:)
          @connection = connection
          @id = id
        end

        def call
          response = @connection.delete("/monitors/#{@id}")
          Resources::SearchMonitor.from_response(response.body)
        end
      end
    end
  end
end
