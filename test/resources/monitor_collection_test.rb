require "test_helper"

class MonitorCollectionTest < Minitest::Test
  def test_initializes_with_data_has_more_and_next_cursor
    monitor1 = Exa::Resources::Monitor.new(id: "mon_1", status: "active")
    monitor2 = Exa::Resources::Monitor.new(id: "mon_2", status: "pending")

    collection = Exa::Resources::MonitorCollection.new(
      data: [monitor1, monitor2],
      has_more: true,
      next_cursor: "cursor_123"
    )

    assert_equal 2, collection.data.length
    assert_equal monitor1, collection.data.first
    assert_equal monitor2, collection.data.last
    assert_equal true, collection.has_more
    assert_equal "cursor_123", collection.next_cursor
  end

  def test_empty_returns_true_when_data_is_empty
    collection = Exa::Resources::MonitorCollection.new(data: [], has_more: false)
    assert collection.empty?
  end

  def test_empty_returns_false_when_data_is_not_empty
    monitor = Exa::Resources::Monitor.new(id: "mon_1", status: "active")
    collection = Exa::Resources::MonitorCollection.new(data: [monitor], has_more: false)
    refute collection.empty?
  end

  def test_to_h_returns_hash_with_data_has_more_next_cursor
    monitor = Exa::Resources::Monitor.new(id: "mon_1", status: "active")
    collection = Exa::Resources::MonitorCollection.new(
      data: [monitor],
      has_more: true,
      next_cursor: "cursor_123"
    )

    hash = collection.to_h

    assert_equal [monitor], hash[:data]
    assert_equal true, hash[:has_more]
    assert_equal "cursor_123", hash[:next_cursor]
  end
end
