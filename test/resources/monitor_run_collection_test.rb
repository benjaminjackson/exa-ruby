require "test_helper"

class MonitorRunCollectionTest < Minitest::Test
  def test_initializes_with_data_has_more_and_next_cursor
    run1 = Exa::Resources::MonitorRun.new(id: "run_1", status: "completed")
    run2 = Exa::Resources::MonitorRun.new(id: "run_2", status: "running")

    collection = Exa::Resources::MonitorRunCollection.new(
      data: [run1, run2],
      has_more: true,
      next_cursor: "cursor_456"
    )

    assert_equal 2, collection.data.length
    assert_equal run1, collection.data.first
    assert_equal run2, collection.data.last
    assert_equal true, collection.has_more
    assert_equal "cursor_456", collection.next_cursor
  end

  def test_empty_returns_true_when_data_is_empty
    collection = Exa::Resources::MonitorRunCollection.new(data: [], has_more: false)
    assert collection.empty?
  end

  def test_empty_returns_false_when_data_is_not_empty
    run = Exa::Resources::MonitorRun.new(id: "run_1", status: "completed")
    collection = Exa::Resources::MonitorRunCollection.new(data: [run], has_more: false)
    refute collection.empty?
  end

  def test_to_h_returns_hash_with_data_has_more_next_cursor
    run = Exa::Resources::MonitorRun.new(id: "run_1", status: "completed")
    collection = Exa::Resources::MonitorRunCollection.new(
      data: [run],
      has_more: true,
      next_cursor: "cursor_456"
    )

    hash = collection.to_h

    assert_equal [run], hash[:data]
    assert_equal true, hash[:has_more]
    assert_equal "cursor_456", hash[:next_cursor]
  end
end
