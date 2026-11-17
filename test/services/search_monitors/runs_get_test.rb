require "test_helper"

class SearchMonitorsRunsGetTest < Minitest::Test
  def test_call_gets_one_run
    stub_request(:get, "https://api.exa.ai/monitors/mon_abc123/runs/run_1")
      .to_return(
        status: 200,
        body: { id: "run_1", monitorId: "mon_abc123", status: "failed", failReason: "webhook_unreachable", failedAt: "2026-11-16T01:00:00Z" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    connection = Exa::Connection.build(api_key: "test_key")

    result = Exa::Services::SearchMonitors::RunsGet.new(connection, monitor_id: "mon_abc123", run_id: "run_1").call

    assert_requested :get, "https://api.exa.ai/monitors/mon_abc123/runs/run_1"
    assert result.failed?
    assert_equal "webhook_unreachable", result.fail_reason
    assert_equal "2026-11-16T01:00:00Z", result.failed_at
  end
end
