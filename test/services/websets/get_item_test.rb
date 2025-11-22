# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      class GetItemTest < Minitest::Test
        def setup
          @connection = Exa::Connection.build(api_key: "test_key")
        end

        def test_initialize_with_connection_webset_id_and_item_id
          service = GetItem.new(@connection, webset_id: "ws_123", id: "item_456")

          assert_instance_of GetItem, service
        end

        def test_call_gets_item_by_id
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123/items/item_456")
            .to_return(
              status: 200,
              body: {
                id: "item_456",
                object: "webset.item",
                url: "https://example.com",
                title: "Example Company",
                createdAt: "2024-01-15T10:30:00Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetItem.new(@connection, webset_id: "ws_123", id: "item_456")
          service.call

          assert_requested :get, "https://api.exa.ai/websets/v0/websets/ws_123/items/item_456"
        end

        def test_call_returns_item_hash
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123/items/item_789")
            .to_return(
              status: 200,
              body: {
                id: "item_789",
                object: "webset.item",
                url: "https://example.com",
                title: "Example Company"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetItem.new(@connection, webset_id: "ws_123", id: "item_789")
          result = service.call

          assert_instance_of Hash, result
          assert_equal "item_789", result["id"]
          assert_equal "webset.item", result["object"]
          assert_equal "https://example.com", result["url"]
          assert_equal "Example Company", result["title"]
        end

        def test_call_raises_not_found_on_404
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123/items/nonexistent")
            .to_return(
              status: 404,
              body: { error: "Item not found" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetItem.new(@connection, webset_id: "ws_123", id: "nonexistent")

          assert_raises(Exa::NotFound) do
            service.call
          end
        end

        def test_call_raises_unauthorized_on_401
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/ws_123/items/item_456")
            .to_return(
              status: 401,
              body: { error: "Invalid API key" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetItem.new(@connection, webset_id: "ws_123", id: "item_456")

          assert_raises(Exa::Unauthorized) do
            service.call
          end
        end
      end
    end
  end
end
