# frozen_string_literal: true

require_relative "../../resources/search_monitor"
require_relative "../../resources/search_monitor_list"

module Exa
  module Services
    module SearchMonitors
      # GET /monitors — list search monitors. Takes status, name, cursor, limit,
      # and metadata (a hash, sent as metadata[key]=value).
      class List
        def initialize(connection, **params)
          @connection = connection
          @params = params
        end

        def call
          body = @connection.get("/monitors", @params).body

          Resources::SearchMonitorList.new(
            data: body["data"].map { |monitor| Resources::SearchMonitor.from_response(monitor) },
            has_more: body["hasMore"],
            next_cursor: body["nextCursor"]
          )
        end
      end
    end
  end
end
