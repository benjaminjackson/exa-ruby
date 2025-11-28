# frozen_string_literal: true

module Exa
  module Services
    module Websets
      module Monitors
        module Runs
          class List
            def initialize(connection, monitor_id:, **params)
              @connection = connection
              @monitor_id = monitor_id
              @params = params
            end

            def call
              response = @connection.get("/websets/v0/monitors/#{@monitor_id}/runs", @params)
              body = response.body

              Resources::MonitorRunCollection.new(
                data: body["data"],
                has_more: body["hasMore"],
                next_cursor: body["nextCursor"]
              )
            end
          end
        end
      end
    end
  end
end
