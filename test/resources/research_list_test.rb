require "test_helper"

class ResearchListTest < Minitest::Test
  def test_initialize_with_data_has_more_and_next_cursor
    list = Exa::Resources::ResearchList.new(
      data: [],
      has_more: false,
      next_cursor: nil
    )

    assert_equal [], list.data
    assert_equal false, list.has_more
    assert_nil list.next_cursor
  end

  def test_initialize_with_next_cursor_for_pagination
    list = Exa::Resources::ResearchList.new(
      data: [],
      has_more: true,
      next_cursor: "cursor123"
    )

    assert_equal "cursor123", list.next_cursor
  end

  def test_immutability
    list = Exa::Resources::ResearchList.new(
      data: [],
      has_more: false,
      next_cursor: nil
    )

    assert_raises(FrozenError) do
      list.data = []
    end
  end

  def test_to_h_returns_correct_hash
    data = [{ id: "123" }]
    list = Exa::Resources::ResearchList.new(
      data: data,
      has_more: true,
      next_cursor: "cursor456"
    )

    expected = {
      data: data,
      has_more: true,
      next_cursor: "cursor456"
    }

    assert_equal expected, list.to_h
  end
end
