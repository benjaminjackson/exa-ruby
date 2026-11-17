require "test_helper"

class SearchMonitorsGetTest < Minitest::Test
  def test_call_gets_monitor
    stub_request(:get, "https://api.exa.ai/monitors/mon_abc123")
      .to_return(
        status: 200,
        body: { id: "mon_abc123", status: "disabled", outputSchema: { type: "object" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    connection = Exa::Connection.build(api_key: "test_key")

    result = Exa::Services::SearchMonitors::Get.new(connection, id: "mon_abc123").call

    assert_requested :get, "https://api.exa.ai/monitors/mon_abc123"
    assert_equal "mon_abc123", result.id
    assert result.disabled?
    assert_equal({ "type" => "object" }, result.output_schema)
  end

  def test_call_raises_not_found_on_404
    stub_request(:get, "https://api.exa.ai/monitors/mon_missing")
      .to_return(status: 404, body: { error: "Not found" }.to_json, headers: { "Content-Type" => "application/json" })
    connection = Exa::Connection.build(api_key: "test_key")

    assert_raises(Exa::NotFound) do
      Exa::Services::SearchMonitors::Get.new(connection, id: "mon_missing").call
    end
  end
end
