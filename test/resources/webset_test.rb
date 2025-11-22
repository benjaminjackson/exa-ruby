# frozen_string_literal: true

require "test_helper"

module Exa
  module Resources
    class WebsetTest < Minitest::Test
      def sample_webset_data
        {
          "id" => "ws_123",
          "object" => "webset",
          "status" => "idle",
          "externalId" => "ext_456",
          "title" => "Marketing Agencies",
          "searches" => [
            {
              "id" => "search_1",
              "object" => "webset_search",
              "status" => "completed",
              "query" => "marketing agencies"
            }
          ],
          "imports" => [],
          "enrichments" => [],
          "monitors" => [],
          "excludes" => [],
          "metadata" => { "custom_field" => "value" },
          "createdAt" => "2025-01-01T00:00:00Z",
          "updatedAt" => "2025-01-02T00:00:00Z",
          "items" => [
            {
              "id" => "item_1",
              "object" => "webset_item",
              "source" => "search",
              "sourceId" => "search_1"
            }
          ]
        }
      end

      def test_initialize_with_full_data
        webset = Webset.new(**symbolize_keys(sample_webset_data))

        assert_instance_of Webset, webset
        assert_equal "ws_123", webset.id
        assert_equal "webset", webset.object
        assert_equal "idle", webset.status
        assert_equal "Marketing Agencies", webset.title
      end

      def test_initialize_with_minimal_data
        webset = Webset.new(
          id: "ws_minimal",
          object: "webset",
          status: "processing"
        )

        assert_equal "ws_minimal", webset.id
        assert_equal "processing", webset.status
        assert_nil webset.title
        assert_nil webset.metadata
      end

      def test_frozen_after_initialization
        webset = Webset.new(id: "ws_1", object: "webset", status: "idle")

        assert webset.frozen?
      end

      def test_accesses_nested_arrays
        webset = Webset.new(**symbolize_keys(sample_webset_data))

        assert_equal 1, webset.searches.length
        assert_equal "search_1", webset.searches.first["id"]
        assert_equal 1, webset.items.length
      end

      def test_accesses_metadata
        webset = Webset.new(
          id: "ws_test",
          object: "webset",
          status: "idle",
          metadata: { "custom_field" => "value" }
        )

        assert_instance_of Hash, webset.metadata
        assert_equal "value", webset.metadata["custom_field"]
      end

      def test_status_helpers
        idle_webset = Webset.new(id: "ws_1", object: "webset", status: "idle")
        processing_webset = Webset.new(id: "ws_2", object: "webset", status: "processing")

        assert idle_webset.idle?
        refute idle_webset.processing?

        assert processing_webset.processing?
        refute processing_webset.idle?
      end

      def test_to_h_returns_hash_representation
        webset = Webset.new(
          id: "ws_test",
          object: "webset",
          status: "idle",
          title: "Test"
        )

        hash = webset.to_h

        assert_equal "ws_test", hash[:id]
        assert_equal "webset", hash[:object]
        assert_equal "idle", hash[:status]
        assert_equal "Test", hash[:title]
      end

      private

      def symbolize_keys(hash)
        hash.transform_keys { |k| k.to_s.gsub(/([A-Z])/, '_\1').downcase.to_sym }
            .transform_values { |v| v.is_a?(Hash) ? symbolize_keys(v) : v }
      end
    end
  end
end
