# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      class CancelSearchTest < Minitest::Test
        def setup
          @connection = Exa::Connection.build(api_key: "test_key")
          @webset_id = "ws_abc123"
          @search_id = "search_xyz789"
        end

        def test_initialize_with_connection_and_ids
          service = CancelSearch.new(
            @connection,
            webset_id: @webset_id,
            id: @search_id
          )

          assert_instance_of CancelSearch, service
        end

        def test_call_cancels_search
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches/#{@search_id}/cancel")
            .to_return(
              status: 200,
              body: {
                id: @search_id,
                object: "webset_search",
                status: "canceled",
                websetId: @webset_id,
                query: "test query",
                canceledAt: "2023-11-07T05:32:00Z",
                canceledReason: "user_requested",
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:32:00Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CancelSearch.new(
            @connection,
            webset_id: @webset_id,
            id: @search_id
          )
          service.call

          assert_requested :post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches/#{@search_id}/cancel"
        end

        def test_call_returns_canceled_search_object
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches/#{@search_id}/cancel")
            .to_return(
              status: 200,
              body: {
                id: @search_id,
                object: "webset_search",
                status: "canceled",
                websetId: @webset_id,
                query: "long running search",
                canceledAt: "2023-11-07T05:32:00Z",
                canceledReason: "user_requested",
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:32:00Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CancelSearch.new(
            @connection,
            webset_id: @webset_id,
            id: @search_id
          )
          result = service.call

          assert_instance_of Exa::Resources::WebsetSearch, result
          assert_equal @search_id, result.id
          assert_equal "canceled", result.status
          assert result.canceled?
          refute result.running?
          refute result.completed?
          assert_equal "user_requested", result.canceled_reason
          refute_nil result.canceled_at
        end

        def test_call_raises_not_found_on_404
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches/nonexistent/cancel")
            .to_return(
              status: 404,
              body: { error: "Search not found" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CancelSearch.new(
            @connection,
            webset_id: @webset_id,
            id: "nonexistent"
          )

          assert_raises(Exa::NotFound) do
            service.call
          end
        end

        def test_call_raises_unauthorized_on_401
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches/#{@search_id}/cancel")
            .to_return(
              status: 401,
              body: { error: "Invalid API key" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CancelSearch.new(
            @connection,
            webset_id: @webset_id,
            id: @search_id
          )

          assert_raises(Exa::Unauthorized) do
            service.call
          end
        end
      end
    end
  end
end
