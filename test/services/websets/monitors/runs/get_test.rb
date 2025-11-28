# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      module Monitors
        module Runs
          class GetTest < Minitest::Test
            def setup
              @connection = Exa::Connection.build(api_key: "test_key")
              @monitor_id = "mon_123"
              @run_id = "run_abc"
            end

            def test_initialize_with_connection_and_ids
              service = Get.new(@connection, monitor_id: @monitor_id, id: @run_id)

              assert_instance_of Get, service
            end

            def test_call_gets_monitor_run_by_id
              stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs/#{@run_id}")
                .to_return(
                  status: 200,
                  body: {
                    id: @run_id,
                    object: "monitor_run",
                    monitorId: @monitor_id,
                    status: "completed",
                    createdAt: "2023-11-07T05:31:56Z",
                    updatedAt: "2023-11-07T05:32:56Z",
                    completedAt: "2023-11-07T05:32:56Z"
                  }.to_json,
                  headers: { "Content-Type" => "application/json" }
                )

              service = Get.new(@connection, monitor_id: @monitor_id, id: @run_id)
              service.call

              assert_requested :get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs/#{@run_id}"
            end

            def test_call_returns_monitor_run_object
              stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs/#{@run_id}")
                .to_return(
                  status: 200,
                  body: {
                    id: @run_id,
                    object: "monitor_run",
                    monitorId: @monitor_id,
                    status: "running",
                    createdAt: "2023-11-07T05:31:56Z",
                    updatedAt: "2023-11-07T05:32:00Z"
                  }.to_json,
                  headers: { "Content-Type" => "application/json" }
                )

              service = Get.new(@connection, monitor_id: @monitor_id, id: @run_id)
              result = service.call

              assert_instance_of Exa::Resources::MonitorRun, result
              assert_equal @run_id, result.id
              assert_equal "monitor_run", result.object
              assert_equal @monitor_id, result.monitor_id
              assert_equal "running", result.status
              assert result.running?
              refute result.completed?
            end

            def test_call_returns_failed_monitor_run
              stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs/#{@run_id}")
                .to_return(
                  status: 200,
                  body: {
                    id: @run_id,
                    object: "monitor_run",
                    monitorId: @monitor_id,
                    status: "failed",
                    failedAt: "2023-11-07T05:33:00Z",
                    failedReason: "timeout",
                    createdAt: "2023-11-07T05:31:56Z",
                    updatedAt: "2023-11-07T05:33:00Z"
                  }.to_json,
                  headers: { "Content-Type" => "application/json" }
                )

              service = Get.new(@connection, monitor_id: @monitor_id, id: @run_id)
              result = service.call

              assert_equal "failed", result.status
              assert_equal "timeout", result.failed_reason
              refute_nil result.failed_at
              assert result.failed?
              refute result.completed?
            end

            def test_call_raises_unauthorized_on_401
              stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs/#{@run_id}")
                .to_return(
                  status: 401,
                  body: { error: "Invalid API key" }.to_json,
                  headers: { "Content-Type" => "application/json" }
                )

              service = Get.new(@connection, monitor_id: @monitor_id, id: @run_id)

              assert_raises(Exa::Unauthorized) do
                service.call
              end
            end

            def test_call_raises_not_found_on_404
              stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs/run_nonexistent")
                .to_return(
                  status: 404,
                  body: { error: "Monitor run not found" }.to_json,
                  headers: { "Content-Type" => "application/json" }
                )

              service = Get.new(@connection, monitor_id: @monitor_id, id: "run_nonexistent")

              assert_raises(Exa::NotFound) do
                service.call
              end
            end

            def test_call_raises_server_error_on_500
              stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs/#{@run_id}")
                .to_return(
                  status: 500,
                  body: { error: "Internal server error" }.to_json,
                  headers: { "Content-Type" => "application/json" }
                )

              service = Get.new(@connection, monitor_id: @monitor_id, id: @run_id)

              assert_raises(Exa::InternalServerError) do
                service.call
              end
            end
          end
        end
      end
    end
  end
end
