# frozen_string_literal: true

require_relative "../../resources/search_monitor_trigger_result"

module Exa
  module Services
    module SearchMonitors
      # POST /monitors/{id}/trigger — run the monitor now (status active or paused).
      class Trigger
        def initialize(connection, id:)
          @connection = connection
          @id = id
        end

        def call
          response = @connection.post("/monitors/#{@id}/trigger")
          Resources::SearchMonitorTriggerResult.new(triggered: response.body["triggered"])
        end
      end
    end
  end
end
