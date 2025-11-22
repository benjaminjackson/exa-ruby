# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      class DeleteItemTest < Minitest::Test
        def setup
          @connection = Exa::Connection.build(api_key: "test_key")
        end

        def test_initialize_with_connection_webset_id_and_item_id
          service = DeleteItem.new(@connection, webset_id: "ws_123", id: "item_456")

          assert_instance_of DeleteItem, service
        end

        def test_call_deletes_item_by_id
          stub_request(:delete, "https://api.exa.ai/websets/v0/websets/ws_123/items/item_456")
            .to_return(
              status: 204,
              body: "",
              headers: {}
            )

          service = DeleteItem.new(@connection, webset_id: "ws_123", id: "item_456")
          service.call

          assert_requested :delete, "https://api.exa.ai/websets/v0/websets/ws_123/items/item_456"
        end

        def test_call_returns_true_on_successful_delete
          stub_request(:delete, "https://api.exa.ai/websets/v0/websets/ws_123/items/item_789")
            .to_return(
              status: 204,
              body: "",
              headers: {}
            )

          service = DeleteItem.new(@connection, webset_id: "ws_123", id: "item_789")
          result = service.call

          assert_equal true, result
        end

        def test_call_raises_not_found_on_404
          stub_request(:delete, "https://api.exa.ai/websets/v0/websets/ws_123/items/nonexistent")
            .to_return(
              status: 404,
              body: { error: "Item not found" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = DeleteItem.new(@connection, webset_id: "ws_123", id: "nonexistent")

          assert_raises(Exa::NotFound) do
            service.call
          end
        end

        def test_call_raises_unauthorized_on_401
          stub_request(:delete, "https://api.exa.ai/websets/v0/websets/ws_123/items/item_456")
            .to_return(
              status: 401,
              body: { error: "Invalid API key" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = DeleteItem.new(@connection, webset_id: "ws_123", id: "item_456")

          assert_raises(Exa::Unauthorized) do
            service.call
          end
        end
      end
    end
  end
end
