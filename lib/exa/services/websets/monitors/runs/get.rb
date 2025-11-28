# frozen_string_literal: true

module Exa
  module Services
    module Websets
      module Monitors
        module Runs
          class Get
            def initialize(connection, monitor_id:, id:, **params)
              @connection = connection
              @monitor_id = monitor_id
              @id = id
              @params = params
            end

            def call
              response = @connection.get("/websets/v0/monitors/#{@monitor_id}/runs/#{@id}", @params)
              body = response.body

              Resources::MonitorRun.new(
                id: body["id"],
                object: body["object"],
                monitor_id: body["monitorId"],
                status: body["status"],
                created_at: body["createdAt"],
                updated_at: body["updatedAt"],
                completed_at: body["completedAt"],
                failed_at: body["failedAt"],
                failed_reason: body["failedReason"]
              )
            end
          end
        end
      end
    end
  end
end
