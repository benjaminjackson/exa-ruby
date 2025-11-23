# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      module Monitors
        class GetTest < Minitest::Test
          def setup
            @connection = Exa::Connection.build(api_key: "test_key")
            @monitor_id = "mon_123"
          end

          def test_initialize_with_connection_and_id
            service = Get.new(@connection, id: @monitor_id)

            assert_instance_of Get, service
          end

          def test_call_gets_monitor_by_id
            stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}")
              .to_return(
                status: 200,
                body: {
                  id: @monitor_id,
                  object: "monitor",
                  status: "active",
                  websetId: "ws_abc",
                  cadence: {
                    cron: "0 0 * * *",
                    timezone: "America/New_York"
                  },
                  behavior: {
                    type: "search",
                    config: {
                      query: "AI startups",
                      count: 10
                    }
                  },
                  createdAt: "2023-11-07T05:31:56Z",
                  updatedAt: "2023-11-07T05:31:56Z"
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Get.new(@connection, id: @monitor_id)
            service.call

            assert_requested :get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}"
          end

          def test_call_returns_monitor_object
            stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}")
              .to_return(
                status: 200,
                body: {
                  id: @monitor_id,
                  object: "monitor",
                  status: "active",
                  websetId: "ws_abc",
                  cadence: {
                    cron: "0 */6 * * *",
                    timezone: "UTC"
                  },
                  behavior: {
                    type: "refresh"
                  },
                  createdAt: "2023-11-07T05:31:56Z",
                  updatedAt: "2023-11-07T05:31:56Z"
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Get.new(@connection, id: @monitor_id)
            result = service.call

            assert_instance_of Exa::Resources::Monitor, result
            assert_equal @monitor_id, result.id
            assert_equal "monitor", result.object
            assert_equal "active", result.status
            assert_equal "ws_abc", result.webset_id
            assert_equal "0 */6 * * *", result.cadence["cron"]
            assert_equal "UTC", result.cadence["timezone"]
            assert_equal "refresh", result.behavior["type"]
            assert result.active?
            refute result.pending?
          end

          def test_call_raises_unauthorized_on_401
            stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}")
              .to_return(
                status: 401,
                body: { error: "Invalid API key" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Get.new(@connection, id: @monitor_id)

            assert_raises(Exa::Unauthorized) do
              service.call
            end
          end

          def test_call_raises_not_found_on_404
            stub_request(:get, "https://api.exa.ai/websets/v0/monitors/mon_nonexistent")
              .to_return(
                status: 404,
                body: { error: "Monitor not found" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Get.new(@connection, id: "mon_nonexistent")

            assert_raises(Exa::NotFound) do
              service.call
            end
          end

          def test_call_raises_server_error_on_500
            stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}")
              .to_return(
                status: 500,
                body: { error: "Internal server error" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Get.new(@connection, id: @monitor_id)

            assert_raises(Exa::InternalServerError) do
              service.call
            end
          end
        end
      end
    end
  end
end
