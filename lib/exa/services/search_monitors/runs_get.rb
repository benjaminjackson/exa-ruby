# frozen_string_literal: true

require_relative "../../resources/search_monitor_run"

module Exa
  module Services
    module SearchMonitors
      # GET /monitors/{id}/runs/{runId}
      class RunsGet
        def initialize(connection, monitor_id:, run_id:)
          @connection = connection
          @monitor_id = monitor_id
          @run_id = run_id
        end

        def call
          response = @connection.get("/monitors/#{@monitor_id}/runs/#{@run_id}")
          Resources::SearchMonitorRun.from_response(response.body)
        end
      end
    end
  end
end
