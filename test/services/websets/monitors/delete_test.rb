# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      module Monitors
        class DeleteTest < Minitest::Test
          def setup
            @connection = Exa::Connection.build(api_key: "test_key")
            @monitor_id = "mon_123"
          end

          def test_initialize_with_connection_and_id
            service = Delete.new(@connection, id: @monitor_id)

            assert_instance_of Delete, service
          end

          def test_call_deletes_monitor_by_id
            stub_request(:delete, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}")
              .to_return(
                status: 200,
                body: {
                  id: @monitor_id,
                  object: "monitor",
                  status: "enabled",
                  websetId: "ws_123",
                  cadence: {
                    cron: "0 9 * * MON",
                    timezone: "America/New_York"
                  },
                  behavior: {
                    type: "search",
                    config: {
                      query: "AI infrastructure startups",
                      criteria: [{ description: "Series A funding" }],
                      count: 10,
                      behavior: "append"
                    }
                  },
                  createdAt: "2024-01-15T10:30:00Z",
                  updatedAt: "2024-01-15T10:30:00Z"
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Delete.new(@connection, id: @monitor_id)
            result = service.call

            assert_requested :delete, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}"
            assert_instance_of Exa::Resources::Monitor, result
            assert_equal @monitor_id, result.id
          end

          def test_call_raises_unauthorized_on_401
            stub_request(:delete, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}")
              .to_return(
                status: 401,
                body: { error: "Invalid API key" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Delete.new(@connection, id: @monitor_id)

            assert_raises(Exa::Unauthorized) do
              service.call
            end
          end

          def test_call_raises_not_found_on_404
            stub_request(:delete, "https://api.exa.ai/websets/v0/monitors/mon_nonexistent")
              .to_return(
                status: 404,
                body: { error: "Monitor not found" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Delete.new(@connection, id: "mon_nonexistent")

            assert_raises(Exa::NotFound) do
              service.call
            end
          end

          def test_call_raises_server_error_on_500
            stub_request(:delete, "https://api.exa.ai/websets/v0/monitors/#{@monitor_id}")
              .to_return(
                status: 500,
                body: { error: "Internal server error" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Delete.new(@connection, id: @monitor_id)

            assert_raises(Exa::InternalServerError) do
              service.call
            end
          end
        end
      end
    end
  end
end
