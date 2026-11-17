require "test_helper"

class SearchMonitorsTriggerTest < Minitest::Test
  def test_call_posts_to_trigger
    stub_request(:post, "https://api.exa.ai/monitors/mon_abc123/trigger")
      .to_return(status: 200, body: { triggered: true }.to_json, headers: { "Content-Type" => "application/json" })
    connection = Exa::Connection.build(api_key: "test_key")

    result = Exa::Services::SearchMonitors::Trigger.new(connection, id: "mon_abc123").call

    assert_requested :post, "https://api.exa.ai/monitors/mon_abc123/trigger"
    assert_instance_of Exa::Resources::SearchMonitorTriggerResult, result
    assert_equal true, result.triggered
  end
end
