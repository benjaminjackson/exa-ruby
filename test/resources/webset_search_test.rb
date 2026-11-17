require "test_helper"

class WebsetSearchTest < Minitest::Test
  # Every value of the spec's status enum has a helper that is true only for that value.
  def test_each_spec_status_has_a_helper
    %w[created pending running completed canceled].each do |status|
      resource = Exa::Resources::WebsetSearch.new(id: "ws_search_1", object: "webset_search", status: status)

      %w[created pending running completed canceled].each do |other|
        assert_equal other == status, resource.public_send("#{other}?"), "#{other}? with status #{status}"
      end
    end
  end

  # A pending search has not finished, so code that waits on in_progress? keeps waiting.
  def test_in_progress_is_true_when_pending
    resource = Exa::Resources::WebsetSearch.new(id: "ws_search_1", object: "webset_search", status: "pending")

    assert resource.in_progress?
  end
end
