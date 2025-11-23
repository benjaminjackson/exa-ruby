# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      module Monitors
        class CreateTest < Minitest::Test
          def setup
            @connection = Exa::Connection.build(api_key: "test_key")
            @webset_id = "ws_abc123"
          end

          def test_initialize_with_connection_and_params
            service = Create.new(
              @connection,
              webset_id: @webset_id,
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
              }
            )

            assert_instance_of Create, service
          end

          def test_call_creates_monitor_with_search_behavior
            stub_request(:post, "https://api.exa.ai/websets/v0/monitors")
              .with(
                body: {
                  websetId: @webset_id,
                  cadence: {
                    cron: "0 0 * * *",
                    timezone: "America/New_York"
                  },
                  behavior: {
                    type: "search",
                    config: {
                      query: "AI startups with Series A funding",
                      count: 10
                    }
                  }
                }.to_json
              )
              .to_return(
                status: 201,
                body: {
                  id: "mon_xyz789",
                  object: "monitor",
                  status: "pending",
                  websetId: @webset_id,
                  cadence: {
                    cron: "0 0 * * *",
                    timezone: "America/New_York"
                  },
                  behavior: {
                    type: "search",
                    config: {
                      query: "AI startups with Series A funding",
                      count: 10
                    }
                  },
                  createdAt: "2023-11-07T05:31:56Z",
                  updatedAt: "2023-11-07T05:31:56Z"
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Create.new(
              @connection,
              webset_id: @webset_id,
              cadence: {
                cron: "0 0 * * *",
                timezone: "America/New_York"
              },
              behavior: {
                type: "search",
                config: {
                  query: "AI startups with Series A funding",
                  count: 10
                }
              }
            )
            result = service.call

            assert_instance_of Exa::Resources::Monitor, result
            assert_equal "mon_xyz789", result.id
            assert_equal "monitor", result.object
            assert_equal "pending", result.status
            assert_equal @webset_id, result.webset_id
            assert_equal "0 0 * * *", result.cadence["cron"]
            assert_equal "America/New_York", result.cadence["timezone"]
            assert_equal "search", result.behavior["type"]
            assert_equal "AI startups with Series A funding", result.behavior["config"]["query"]
            assert_equal 10, result.behavior["config"]["count"]
            assert result.pending?
            refute result.active?
          end

          def test_call_creates_monitor_with_refresh_behavior
            stub_request(:post, "https://api.exa.ai/websets/v0/monitors")
              .with(
                body: {
                  websetId: @webset_id,
                  cadence: {
                    cron: "0 */6 * * *",
                    timezone: "UTC"
                  },
                  behavior: {
                    type: "refresh"
                  }
                }.to_json
              )
              .to_return(
                status: 201,
                body: {
                  id: "mon_refresh",
                  object: "monitor",
                  status: "active",
                  websetId: @webset_id,
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

            service = Create.new(
              @connection,
              webset_id: @webset_id,
              cadence: {
                cron: "0 */6 * * *",
                timezone: "UTC"
              },
              behavior: {
                type: "refresh"
              }
            )
            result = service.call

            assert_equal "refresh", result.behavior["type"]
            assert_nil result.behavior["config"]
            assert result.active?
            refute result.pending?
          end

          def test_call_creates_monitor_with_search_mode_override
            stub_request(:post, "https://api.exa.ai/websets/v0/monitors")
              .with(
                body: {
                  websetId: @webset_id,
                  cadence: {
                    cron: "0 0 * * *",
                    timezone: "America/Los_Angeles"
                  },
                  behavior: {
                    type: "search",
                    config: {
                      query: "SaaS companies",
                      count: 20,
                      mode: "override"
                    }
                  }
                }.to_json
              )
              .to_return(
                status: 201,
                body: {
                  id: "mon_override",
                  object: "monitor",
                  status: "pending",
                  websetId: @webset_id,
                  cadence: {
                    cron: "0 0 * * *",
                    timezone: "America/Los_Angeles"
                  },
                  behavior: {
                    type: "search",
                    config: {
                      query: "SaaS companies",
                      count: 20,
                      mode: "override"
                    }
                  },
                  createdAt: "2023-11-07T05:31:56Z",
                  updatedAt: "2023-11-07T05:31:56Z"
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Create.new(
              @connection,
              webset_id: @webset_id,
              cadence: {
                cron: "0 0 * * *",
                timezone: "America/Los_Angeles"
              },
              behavior: {
                type: "search",
                config: {
                  query: "SaaS companies",
                  count: 20,
                  mode: "override"
                }
              }
            )
            result = service.call

            assert_equal "override", result.behavior["config"]["mode"]
          end

          def test_call_raises_unauthorized_on_401
            stub_request(:post, "https://api.exa.ai/websets/v0/monitors")
              .to_return(
                status: 401,
                body: { error: "Invalid API key" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Create.new(
              @connection,
              webset_id: @webset_id,
              cadence: { cron: "0 0 * * *", timezone: "UTC" },
              behavior: { type: "refresh" }
            )

            assert_raises(Exa::Unauthorized) do
              service.call
            end
          end

          def test_call_raises_unprocessable_entity_on_422
            stub_request(:post, "https://api.exa.ai/websets/v0/monitors")
              .to_return(
                status: 422,
                body: { error: "Invalid cron expression" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Create.new(
              @connection,
              webset_id: @webset_id,
              cadence: { cron: "invalid", timezone: "UTC" },
              behavior: { type: "refresh" }
            )

            assert_raises(Exa::UnprocessableEntity) do
              service.call
            end
          end

          def test_call_raises_internal_server_error_on_500
            stub_request(:post, "https://api.exa.ai/websets/v0/monitors")
              .to_return(
                status: 500,
                body: { error: "Internal server error" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Create.new(
              @connection,
              webset_id: @webset_id,
              cadence: { cron: "0 0 * * *", timezone: "UTC" },
              behavior: { type: "refresh" }
            )

            assert_raises(Exa::InternalServerError) do
              service.call
            end
          end
        end
      end
    end
  end
end
