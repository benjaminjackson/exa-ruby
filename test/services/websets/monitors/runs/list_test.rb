# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      module Monitors
        module Runs
          class ListTest < Minitest::Test
            def setup
              @connection = Exa::Connection.build(api_key: "test_key")
              @monitor_id = "mon_123"
            end

            def test_initialize_with_connection_and_params
              service = List.new(@connection, monitor_id: @monitor_id, limit: 10)

              assert_instance_of List, service
            end

            def test_call_gets_monitor_runs_list_endpoint
              stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs")
                .to_return(
                  status: 200,
                  body: {
                    data: [],
                    hasMore: false,
                    nextCursor: nil
                  }.to_json,
                  headers: { "Content-Type" => "application/json" }
                )

              service = List.new(@connection, monitor_id: @monitor_id)
              service.call

              assert_requested :get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs"
            end

            def test_call_returns_monitor_run_collection_object
              stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs")
                .to_return(
                  status: 200,
                  body: {
                    data: [
                      {
                        id: "run_abc",
                        object: "monitor_run",
                        monitorId: @monitor_id,
                        status: "completed",
                        createdAt: "2023-11-07T05:31:56Z",
                        updatedAt: "2023-11-07T05:32:56Z",
                        completedAt: "2023-11-07T05:32:56Z"
                      }
                    ],
                    hasMore: true,
                    nextCursor: "cursor_xyz"
                  }.to_json,
                  headers: { "Content-Type" => "application/json" }
                )

              service = List.new(@connection, monitor_id: @monitor_id)
              result = service.call

              assert_instance_of Exa::Resources::MonitorRunCollection, result
              assert_equal 1, result.data.length
              assert_equal true, result.has_more
              assert_equal "cursor_xyz", result.next_cursor
              refute result.empty?
            end

            def test_call_sends_pagination_parameters
              stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs")
                .with(query: hash_including("cursor" => "next_page", "limit" => "20"))
                .to_return(
                  status: 200,
                  body: {
                    data: [],
                    hasMore: false,
                    nextCursor: nil
                  }.to_json,
                  headers: { "Content-Type" => "application/json" }
                )

              service = List.new(@connection, monitor_id: @monitor_id, cursor: "next_page", limit: 20)
              service.call

              assert_requested :get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs",
                               query: hash_including("cursor" => "next_page", "limit" => "20")
            end

            def test_call_raises_unauthorized_on_401
              stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs")
                .to_return(
                  status: 401,
                  body: { error: "Invalid API key" }.to_json,
                  headers: { "Content-Type" => "application/json" }
                )

              service = List.new(@connection, monitor_id: @monitor_id)

              assert_raises(Exa::Unauthorized) do
                service.call
              end
            end

            def test_call_raises_not_found_on_404
              stub_request(:get, "https://api.exa.ai/websets/v0/monitors/mon_nonexistent/runs")
                .to_return(
                  status: 404,
                  body: { error: "Monitor not found" }.to_json,
                  headers: { "Content-Type" => "application/json" }
                )

              service = List.new(@connection, monitor_id: "mon_nonexistent")

              assert_raises(Exa::NotFound) do
                service.call
              end
            end

            def test_call_raises_server_error_on_500
              stub_request(:get, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}/runs")
                .to_return(
                  status: 500,
                  body: { error: "Internal server error" }.to_json,
                  headers: { "Content-Type" => "application/json" }
                )

              service = List.new(@connection, monitor_id: @monitor_id)

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
