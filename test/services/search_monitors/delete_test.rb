require "test_helper"

class SearchMonitorsDeleteTest < Minitest::Test
  def test_call_deletes_monitor
    stub_request(:delete, "https://api.exa.ai/monitors/mon_abc123")
      .to_return(
        status: 200,
        body: { id: "mon_abc123", name: "AI funding news", status: "active" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    connection = Exa::Connection.build(api_key: "test_key")

    result = Exa::Services::SearchMonitors::Delete.new(connection, id: "mon_abc123").call

    assert_requested :delete, "https://api.exa.ai/monitors/mon_abc123"
    assert_instance_of Exa::Resources::SearchMonitor, result
    assert_equal "mon_abc123", result.id
  end
end
