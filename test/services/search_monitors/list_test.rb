require "test_helper"

class SearchMonitorsListTest < Minitest::Test
  def setup
    super
    @connection = Exa::Connection.build(api_key: "test_key")
  end

  def test_call_gets_monitors_with_filters
    stub_request(:get, "https://api.exa.ai/monitors?status=active&limit=5&metadata%5Bteam%5D=research")
      .to_return(
        status: 200,
        body: { data: [{ id: "mon_abc123", status: "active" }], hasMore: true, nextCursor: "cur_1" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = Exa::Services::SearchMonitors::List.new(
      @connection, status: "active", limit: 5, metadata: { "team" => "research" }
    ).call

    assert_requested :get, "https://api.exa.ai/monitors?status=active&limit=5&metadata%5Bteam%5D=research"
    assert_instance_of Exa::Resources::SearchMonitorList, result
    assert_instance_of Exa::Resources::SearchMonitor, result.data.first
    assert_equal true, result.has_more
    assert_equal "cur_1", result.next_cursor
  end
end
