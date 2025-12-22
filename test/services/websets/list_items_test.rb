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
                ],
                hasMore: false,
                nextCursor: nil
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = ListItems.new(@connection, webset_id: "ws_123")
          service.call

          assert_requested :get, "https://api.exa.ai/websets/v0/websets/ws_123/items"
        end

        def test_call_returns_items_collection
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
                ],
                hasMore: false,
                nextCursor: nil
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = ListItems.new(@connection, webset_id: "ws_456")
          result = service.call

          assert_instance_of Exa::Resources::WebsetItemCollection, result
          assert_equal 1, result.data.length
          assert_equal "item_1", result.data[0]["id"]
          assert_equal "https://example1.com", result.data[0]["url"]
        end

        def test_call_returns_empty_collection_when_no_items
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_empty/items")
            .to_return(
              status: 200,
              body: {
                object: "list",
                data: [],
                hasMore: false,
                nextCursor: nil
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = ListItems.new(@connection, webset_id: "ws_empty")
          result = service.call

          assert_instance_of Exa::Resources::WebsetItemCollection, result
          assert_empty result.data
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

        # Pagination tests
        def test_initialize_accepts_cursor_and_limit_params
          service = ListItems.new(@connection, webset_id: "ws_123", cursor: "abc123", limit: 10)

          assert_instance_of ListItems, service
        end

        def test_call_passes_cursor_to_api
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123/items")
            .with(query: { cursor: "abc123" })
            .to_return(
              status: 200,
              body: {
                object: "list",
                data: [],
                hasMore: false,
                nextCursor: nil
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = ListItems.new(@connection, webset_id: "ws_123", cursor: "abc123")
          service.call

          assert_requested :get, "https://api.exa.ai/websets/v0/websets/ws_123/items", query: { cursor: "abc123" }
        end

        def test_call_passes_limit_to_api
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123/items")
            .with(query: { limit: 10 })
            .to_return(
              status: 200,
              body: {
                object: "list",
                data: [],
                hasMore: false,
                nextCursor: nil
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = ListItems.new(@connection, webset_id: "ws_123", limit: 10)
          service.call

          assert_requested :get, "https://api.exa.ai/websets/v0/websets/ws_123/items", query: { limit: 10 }
        end

        def test_call_returns_webset_item_collection
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123/items")
            .to_return(
              status: 200,
              body: {
                object: "list",
                data: [{ id: "item_1", url: "https://example.com" }],
                hasMore: true,
                nextCursor: "next_page_cursor"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = ListItems.new(@connection, webset_id: "ws_123")
          result = service.call

          assert_instance_of Exa::Resources::WebsetItemCollection, result
        end

        def test_call_includes_pagination_metadata
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123/items")
            .to_return(
              status: 200,
              body: {
                object: "list",
                data: [{ id: "item_1" }],
                hasMore: true,
                nextCursor: "cursor_xyz"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = ListItems.new(@connection, webset_id: "ws_123")
          result = service.call

          assert_equal true, result.has_more
          assert_equal "cursor_xyz", result.next_cursor
          assert_equal 1, result.data.length
        end

        def test_call_handles_cursor_and_limit_together
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123/items")
            .with(query: { cursor: "abc123", limit: 5 })
            .to_return(
              status: 200,
              body: {
                object: "list",
                data: [{ id: "item_1" }],
                hasMore: true,
                nextCursor: "next_cursor"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = ListItems.new(@connection, webset_id: "ws_123", cursor: "abc123", limit: 5)
          result = service.call

          assert_requested :get, "https://api.exa.ai/websets/v0/websets/ws_123/items", query: { cursor: "abc123", limit: 5 }
          assert_instance_of Exa::Resources::WebsetItemCollection, result
        end
      end
    end
  end
end
