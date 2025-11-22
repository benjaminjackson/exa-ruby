# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      class ListTest < Minitest::Test
        def setup
          @connection = Exa::Connection.build(api_key: "test_key")
        end

        def test_initialize_with_connection_and_params
          service = List.new(@connection, limit: 10)

          assert_instance_of List, service
        end

        def test_call_gets_websets_list_endpoint
          stub_request(:get, "https://api.exa.ai/websets/v0/websets")
            .to_return(
              status: 200,
              body: {
                data: [],
                hasMore: false,
                nextCursor: nil
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = List.new(@connection)
          service.call

          assert_requested :get, "https://api.exa.ai/websets/v0/websets"
        end

        def test_call_returns_webset_collection_object
          stub_request(:get, "https://api.exa.ai/websets/v0/websets")
            .to_return(
              status: 200,
              body: {
                data: [
                  { id: "ws_123", object: "webset", status: "idle" }
                ],
                hasMore: true,
                nextCursor: "cursor_abc"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = List.new(@connection)
          result = service.call

          assert_instance_of Exa::Resources::WebsetCollection, result
          assert_equal 1, result.data.length
          assert_equal true, result.has_more
          assert_equal "cursor_abc", result.next_cursor
        end

        def test_call_sends_pagination_parameters
          stub_request(:get, "https://api.exa.ai/websets/v0/websets")
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

          service = List.new(@connection, cursor: "next_page", limit: 20)
          service.call

          assert_requested :get, "https://api.exa.ai/websets/v0/websets",
                           query: hash_including("cursor" => "next_page", "limit" => "20")
        end

        def test_call_raises_unauthorized_on_401
          stub_request(:get, "https://api.exa.ai/websets/v0/websets")
            .to_return(
              status: 401,
              body: { error: "Invalid API key" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = List.new(@connection)

          assert_raises(Exa::Unauthorized) do
            service.call
          end
        end

        def test_call_raises_server_error_on_500
          stub_request(:get, "https://api.exa.ai/websets/v0/websets")
            .to_return(
              status: 500,
              body: { error: "Internal server error" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = List.new(@connection)

          assert_raises(Exa::InternalServerError) do
            service.call
          end
        end
      end
    end
  end
end
