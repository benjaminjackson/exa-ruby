# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      module Monitors
        class UpdateTest < Minitest::Test
          def setup
            @connection = Exa::Connection.build(api_key: "test_key")
            @monitor_id = "mon_123"
          end

          def test_initialize_with_connection_and_params
            service = Update.new(
              @connection,
              id: @monitor_id,
              status: "paused"
            )

            assert_instance_of Update, service
          end

          def test_call_updates_monitor_status
            stub_request(:patch, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}")
              .with(
                body: {
                  status: "paused"
                }.to_json
              )
              .to_return(
                status: 200,
                body: {
                  id: @monitor_id,
                  object: "monitor",
                  status: "paused",
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
                  updatedAt: "2023-11-07T10:00:00Z"
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Update.new(@connection, id: @monitor_id, status: "paused")
            result = service.call

            assert_instance_of Exa::Resources::Monitor, result
            assert_equal "paused", result.status
            assert result.paused?
            refute result.active?
          end

          def test_call_updates_monitor_cadence
            new_cadence = {
              cron: "0 */12 * * *",
              timezone: "UTC"
            }

            stub_request(:patch, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}")
              .with(
                body: {
                  cadence: new_cadence
                }.to_json
              )
              .to_return(
                status: 200,
                body: {
                  id: @monitor_id,
                  object: "monitor",
                  status: "active",
                  websetId: "ws_abc",
                  cadence: new_cadence,
                  behavior: {
                    type: "refresh"
                  },
                  createdAt: "2023-11-07T05:31:56Z",
                  updatedAt: "2023-11-07T10:00:00Z"
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Update.new(@connection, id: @monitor_id, cadence: new_cadence)
            result = service.call

            assert_equal "0 */12 * * *", result.cadence["cron"]
            assert_equal "UTC", result.cadence["timezone"]
          end

          def test_call_updates_monitor_behavior
            new_behavior = {
              type: "search",
              config: {
                query: "new query",
                count: 50,
                mode: "append"
              }
            }

            stub_request(:patch, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}")
              .with(
                body: {
                  behavior: new_behavior
                }.to_json
              )
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
                  behavior: new_behavior,
                  createdAt: "2023-11-07T05:31:56Z",
                  updatedAt: "2023-11-07T10:00:00Z"
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Update.new(@connection, id: @monitor_id, behavior: new_behavior)
            result = service.call

            assert_equal "search", result.behavior["type"]
            assert_equal "new query", result.behavior["config"]["query"]
            assert_equal 50, result.behavior["config"]["count"]
            assert_equal "append", result.behavior["config"]["mode"]
          end

          def test_call_raises_unauthorized_on_401
            stub_request(:patch, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}")
              .to_return(
                status: 401,
                body: { error: "Invalid API key" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Update.new(@connection, id: @monitor_id, status: "paused")

            assert_raises(Exa::Unauthorized) do
              service.call
            end
          end

          def test_call_raises_not_found_on_404
            stub_request(:patch, "https://api.exa.ai/websets/v0/monitors/mon_nonexistent")
              .to_return(
                status: 404,
                body: { error: "Monitor not found" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Update.new(@connection, id: "mon_nonexistent", status: "paused")

            assert_raises(Exa::NotFound) do
              service.call
            end
          end

          def test_call_raises_server_error_on_500
            stub_request(:patch, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}")
              .to_return(
                status: 500,
                body: { error: "Internal server error" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Update.new(@connection, id: @monitor_id, status: "paused")

            assert_raises(Exa::InternalServerError) do
              service.call
            end
          end
        end
      end
    end
  end
end
