# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      class CreateSearchTest < Minitest::Test
        def setup
          @connection = Exa::Connection.build(api_key: "test_key")
          @webset_id = "ws_abc123"
        end

        def test_initialize_with_connection_and_params
          service = CreateSearch.new(
            @connection,
            webset_id: @webset_id,
            query: "test query",
            count: 10
          )

          assert_instance_of CreateSearch, service
        end

        def test_call_creates_search_with_minimal_params
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches")
            .with(
              body: {
                query: "AI startups",
                count: 5
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                id: "search_xyz789",
                object: "webset_search",
                status: "created",
                websetId: @webset_id,
                query: "AI startups",
                count: 5,
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateSearch.new(
            @connection,
            webset_id: @webset_id,
            query: "AI startups",
            count: 5
          )
          result = service.call

          assert_instance_of Exa::Resources::WebsetSearch, result
          assert_equal "search_xyz789", result.id
          assert_equal "webset_search", result.object
          assert_equal "created", result.status
          assert_equal @webset_id, result.webset_id
          assert_equal "AI startups", result.query
          assert_equal 5, result.count
          assert result.created?
          refute result.running?
        end

        def test_call_creates_search_with_entity_type
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches")
            .with(
              body: {
                query: "tech founders",
                count: 10,
                entity: { type: "person" }
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                id: "search_person",
                object: "webset_search",
                status: "running",
                websetId: @webset_id,
                query: "tech founders",
                count: 10,
                entity: { type: "person" },
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateSearch.new(
            @connection,
            webset_id: @webset_id,
            query: "tech founders",
            count: 10,
            entity: { type: "person" }
          )
          result = service.call

          assert_equal "person", result.entity["type"]
          assert result.running?
        end

        def test_call_creates_search_with_criteria
          criteria = [
            { description: "focused on B2B" },
            { description: "Series A or later" }
          ]

          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches")
            .with(
              body: {
                query: "SaaS companies",
                count: 20,
                criteria: criteria
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                id: "search_criteria",
                object: "webset_search",
                status: "running",
                websetId: @webset_id,
                query: "SaaS companies",
                count: 20,
                criteria: [
                  { description: "focused on B2B", successRate: 75 },
                  { description: "Series A or later", successRate: 60 }
                ],
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateSearch.new(
            @connection,
            webset_id: @webset_id,
            query: "SaaS companies",
            count: 20,
            criteria: criteria
          )
          result = service.call

          assert_equal 2, result.criteria.length
          assert_equal "focused on B2B", result.criteria[0]["description"]
          assert_equal 75, result.criteria[0]["successRate"]
        end

        def test_call_creates_search_with_recall
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches")
            .with(
              body: {
                query: "biotech startups",
                count: 50,
                recall: true
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                id: "search_recall",
                object: "webset_search",
                status: "running",
                websetId: @webset_id,
                query: "biotech startups",
                count: 50,
                recall: {
                  expected: {
                    total: 200,
                    confidence: "high",
                    bounds: {
                      min: 180,
                      max: 220
                    }
                  },
                  reasoning: "Based on historical search patterns"
                },
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateSearch.new(
            @connection,
            webset_id: @webset_id,
            query: "biotech startups",
            count: 50,
            recall: true
          )
          result = service.call

          refute_nil result.recall
          assert_equal 200, result.recall["expected"]["total"]
          assert_equal "high", result.recall["expected"]["confidence"]
          assert_equal 180, result.recall["expected"]["bounds"]["min"]
          assert_equal 220, result.recall["expected"]["bounds"]["max"]
        end

        def test_call_creates_search_with_behavior_override
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches")
            .with(
              body: {
                query: "new companies",
                count: 10,
                behavior: "override"
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                id: "search_override",
                object: "webset_search",
                status: "created",
                websetId: @webset_id,
                query: "new companies",
                count: 10,
                behavior: "override",
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateSearch.new(
            @connection,
            webset_id: @webset_id,
            query: "new companies",
            count: 10,
            behavior: "override"
          )
          result = service.call

          assert_equal "override", result.behavior
          assert result.override?
          refute result.append?
        end

        def test_call_creates_search_with_behavior_append
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches")
            .with(
              body: {
                query: "additional companies",
                count: 5,
                behavior: "append"
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                id: "search_append",
                object: "webset_search",
                status: "created",
                websetId: @webset_id,
                query: "additional companies",
                count: 5,
                behavior: "append",
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateSearch.new(
            @connection,
            webset_id: @webset_id,
            query: "additional companies",
            count: 5,
            behavior: "append"
          )
          result = service.call

          assert_equal "append", result.behavior
          assert result.append?
          refute result.override?
        end

        def test_call_creates_search_with_progress
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches")
            .to_return(
              status: 200,
              body: {
                id: "search_progress",
                object: "webset_search",
                status: "running",
                websetId: @webset_id,
                query: "test",
                progress: {
                  found: 25,
                  analyzed: 25,
                  completion: 50,
                  timeLeft: 120
                },
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateSearch.new(
            @connection,
            webset_id: @webset_id,
            query: "test"
          )
          result = service.call

          refute_nil result.progress
          assert_equal 25, result.progress["found"]
          assert_equal 25, result.progress["analyzed"]
          assert_equal 50, result.progress["completion"]
          assert_equal 120, result.progress["timeLeft"]
        end

        def test_call_raises_unauthorized_on_401
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches")
            .to_return(
              status: 401,
              body: { error: "Invalid API key" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateSearch.new(
            @connection,
            webset_id: @webset_id,
            query: "test"
          )

          assert_raises(Exa::Unauthorized) do
            service.call
          end
        end

        def test_call_raises_not_found_on_404
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/nonexistent/searches")
            .to_return(
              status: 404,
              body: { error: "Webset not found" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateSearch.new(
            @connection,
            webset_id: "nonexistent",
            query: "test"
          )

          assert_raises(Exa::NotFound) do
            service.call
          end
        end

        def test_call_raises_api_error_on_500
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches")
            .to_return(
              status: 500,
              body: { error: "Internal server error" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateSearch.new(
            @connection,
            webset_id: @webset_id,
            query: "test"
          )

          assert_raises(Exa::InternalServerError) do
            service.call
          end
        end
      end
    end
  end
end
