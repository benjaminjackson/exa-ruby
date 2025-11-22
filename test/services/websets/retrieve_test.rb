# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      class RetrieveTest < Minitest::Test
        def setup
          @connection = Exa::Connection.build(api_key: "test_key")
        end

        def test_initialize_with_connection_and_id
          service = Retrieve.new(@connection, id: "ws_123")

          assert_instance_of Retrieve, service
        end

        def test_call_gets_webset_by_id
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123")
            .to_return(
              status: 200,
              body: {
                id: "ws_123",
                object: "webset",
                status: "idle",
                searches: [],
                imports: [],
                enrichments: [],
                monitors: [],
                excludes: [],
                items: []
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = Retrieve.new(@connection, id: "ws_123")
          service.call

          assert_requested :get, "https://api.exa.ai/websets/v0/websets/ws_123"
        end

        def test_call_returns_webset_object
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_456")
            .to_return(
              status: 200,
              body: {
                id: "ws_456",
                object: "webset",
                status: "processing",
                title: "Test Webset",
                searches: [{ id: "search_1" }],
                imports: [],
                enrichments: [],
                monitors: [],
                excludes: [],
                items: []
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = Retrieve.new(@connection, id: "ws_456")
          result = service.call

          assert_instance_of Exa::Resources::Webset, result
          assert_equal "ws_456", result.id
          assert_equal "processing", result.status
          assert_equal "Test Webset", result.title
          assert_equal 1, result.searches.length
        end

        def test_call_raises_not_found_on_404
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/nonexistent")
            .to_return(
              status: 404,
              body: { error: "Webset not found" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = Retrieve.new(@connection, id: "nonexistent")

          assert_raises(Exa::NotFound) do
            service.call
          end
        end

        def test_call_raises_unauthorized_on_401
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123")
            .to_return(
              status: 401,
              body: { error: "Invalid API key" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = Retrieve.new(@connection, id: "ws_123")

          assert_raises(Exa::Unauthorized) do
            service.call
          end
        end
      end
    end
  end
end
