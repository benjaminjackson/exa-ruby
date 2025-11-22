# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      class ListItemsTest < Minitest::Test
        def setup
          @connection = Exa::Connection.build(api_key: "test_key")
        end

        def test_initialize_with_connection_and_webset_id
          service = ListItems.new(@connection, webset_id: "ws_123")

          assert_instance_of ListItems, service
        end

        def test_call_gets_items_list
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123/items")
            .to_return(
              status: 200,
              body: {
                object: "list",
                data: [
                  {
                    id: "item_1",
                    object: "webset.item",
                    url: "https://example1.com",
                    title: "Example 1"
                  },
                  {
                    id: "item_2",
                    object: "webset.item",
                    url: "https://example2.com",
                    title: "Example 2"
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = ListItems.new(@connection, webset_id: "ws_123")
          service.call

          assert_requested :get, "https://api.exa.ai/websets/v0/websets/ws_123/items"
        end

        def test_call_returns_items_array
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_456/items")
            .to_return(
              status: 200,
              body: {
                object: "list",
                data: [
                  {
                    id: "item_1",
                    object: "webset.item",
                    url: "https://example1.com"
                  }
                ]
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = ListItems.new(@connection, webset_id: "ws_456")
          result = service.call

          assert_instance_of Array, result
          assert_equal 1, result.length
          assert_equal "item_1", result[0]["id"]
          assert_equal "https://example1.com", result[0]["url"]
        end

        def test_call_returns_empty_array_when_no_items
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_empty/items")
            .to_return(
              status: 200,
              body: {
                object: "list",
                data: []
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = ListItems.new(@connection, webset_id: "ws_empty")
          result = service.call

          assert_instance_of Array, result
          assert_empty result
        end

        def test_call_raises_not_found_on_404
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/nonexistent/items")
            .to_return(
              status: 404,
              body: { error: "Webset not found" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = ListItems.new(@connection, webset_id: "nonexistent")

          assert_raises(Exa::NotFound) do
            service.call
          end
        end

        def test_call_raises_unauthorized_on_401
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123/items")
            .to_return(
              status: 401,
              body: { error: "Invalid API key" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = ListItems.new(@connection, webset_id: "ws_123")

          assert_raises(Exa::Unauthorized) do
            service.call
          end
        end
      end
    end
  end
end
