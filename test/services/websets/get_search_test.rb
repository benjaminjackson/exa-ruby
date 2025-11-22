# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      class GetSearchTest < Minitest::Test
        def setup
          @connection = Exa::Connection.build(api_key: "test_key")
          @webset_id = "ws_abc123"
          @search_id = "search_xyz789"
        end

        def test_initialize_with_connection_and_ids
          service = GetSearch.new(
            @connection,
            webset_id: @webset_id,
            id: @search_id
          )

          assert_instance_of GetSearch, service
        end

        def test_call_gets_search_by_id
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches/#{@search_id}")
            .to_return(
              status: 200,
              body: {
                id: @search_id,
                object: "webset_search",
                status: "completed",
                websetId: @webset_id,
                query: "test query",
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:32:30Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetSearch.new(
            @connection,
            webset_id: @webset_id,
            id: @search_id
          )
          service.call

          assert_requested :get, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches/#{@search_id}"
        end

        def test_call_returns_search_object
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches/#{@search_id}")
            .to_return(
              status: 200,
              body: {
                id: @search_id,
                object: "webset_search",
                status: "completed",
                websetId: @webset_id,
                query: "marketing agencies",
                count: 50,
                behavior: "override",
                progress: {
                  found: 50,
                  analyzed: 50,
                  completion: 100,
                  timeLeft: 0
                },
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:32:30Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetSearch.new(
            @connection,
            webset_id: @webset_id,
            id: @search_id
          )
          result = service.call

          assert_instance_of Exa::Resources::WebsetSearch, result
          assert_equal @search_id, result.id
          assert_equal "completed", result.status
          assert result.completed?
          assert_equal "marketing agencies", result.query
          assert_equal 50, result.count
          assert_equal 100, result.progress["completion"]
        end

        def test_call_returns_search_with_recall
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches/#{@search_id}")
            .to_return(
              status: 200,
              body: {
                id: @search_id,
                object: "webset_search",
                status: "completed",
                websetId: @webset_id,
                query: "biotech companies",
                recall: {
                  expected: {
                    total: 500,
                    confidence: "medium",
                    bounds: {
                      min: 400,
                      max: 600
                    }
                  },
                  reasoning: "Estimate based on domain analysis"
                },
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:32:30Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetSearch.new(
            @connection,
            webset_id: @webset_id,
            id: @search_id
          )
          result = service.call

          refute_nil result.recall
          assert_equal 500, result.recall["expected"]["total"]
          assert_equal "medium", result.recall["expected"]["confidence"]
        end

        def test_call_raises_not_found_on_404
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches/nonexistent")
            .to_return(
              status: 404,
              body: { error: "Search not found" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetSearch.new(
            @connection,
            webset_id: @webset_id,
            id: "nonexistent"
          )

          assert_raises(Exa::NotFound) do
            service.call
          end
        end

        def test_call_raises_unauthorized_on_401
          stub_request(:get, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches/#{@search_id}")
            .to_return(
              status: 401,
              body: { error: "Invalid API key" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetSearch.new(
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
