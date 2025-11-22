# frozen_string_literal: true

require "test_helper"

module Exa
  module Resources
    class WebsetCollectionTest < Minitest::Test
      def test_initialize_with_data_array
        collection = WebsetCollection.new(
          data: [{ "id" => "ws_123", "status" => "idle" }],
          has_more: false,
          next_cursor: nil
        )

        assert_instance_of WebsetCollection, collection
        assert_equal 1, collection.data.length
        assert_equal false, collection.has_more
        assert_nil collection.next_cursor
      end

      def test_initialize_with_pagination
        collection = WebsetCollection.new(
          data: [],
          has_more: true,
          next_cursor: "cursor_abc123"
        )

        assert_equal true, collection.has_more
        assert_equal "cursor_abc123", collection.next_cursor
      end

      def test_initialize_with_empty_data
        collection = WebsetCollection.new(
          data: [],
          has_more: false,
          next_cursor: nil
        )

        assert_empty collection.data
        assert_equal false, collection.has_more
      end

      def test_frozen_after_initialization
        collection = WebsetCollection.new(
          data: [],
          has_more: false,
          next_cursor: nil
        )

        assert collection.frozen?
      end

      def test_to_h_returns_hash_representation
        collection = WebsetCollection.new(
          data: [{ "id" => "ws_1" }],
          has_more: true,
          next_cursor: "next"
        )

        hash = collection.to_h

        assert_equal [{ "id" => "ws_1" }], hash[:data]
        assert_equal true, hash[:has_more]
        assert_equal "next", hash[:next_cursor]
      end

      def test_empty_helper_when_no_data
        collection = WebsetCollection.new(
          data: [],
          has_more: false,
          next_cursor: nil
        )

        assert collection.empty?
      end

      def test_empty_helper_when_has_data
        collection = WebsetCollection.new(
          data: [{ "id" => "ws_1" }],
          has_more: false,
          next_cursor: nil
        )

        refute collection.empty?
      end
    end
  end
end
