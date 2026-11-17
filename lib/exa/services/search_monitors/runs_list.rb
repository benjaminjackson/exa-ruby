# frozen_string_literal: true

require_relative "../../resources/search_monitor_run"
require_relative "../../resources/search_monitor_list"

module Exa
  module Services
    module SearchMonitors
      # GET /monitors/{id}/runs — list the runs of one search monitor.
      class RunsList
        def initialize(connection, monitor_id:, **params)
          @connection = connection
          @monitor_id = monitor_id
          @params = params
        end

        def call
          body = @connection.get("/monitors/#{@monitor_id}/runs", @params).body

          Resources::SearchMonitorList.new(
            data: body["data"].map { |run| Resources::SearchMonitorRun.from_response(run) },
            has_more: body["hasMore"],
            next_cursor: body["nextCursor"]
          )
        end
      end
    end
  end
end
