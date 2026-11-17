require "test_helper"

class SearchMonitorsRunsListTest < Minitest::Test
  def test_call_gets_runs_of_monitor
    stub_request(:get, "https://api.exa.ai/monitors/mon_abc123/runs?limit=10")
      .to_return(
        status: 200,
        body: { data: [{ id: "run_1", monitorId: "mon_abc123", status: "completed", durationMs: 1200 }], hasMore: false }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    connection = Exa::Connection.build(api_key: "test_key")

    result = Exa::Services::SearchMonitors::RunsList.new(connection, monitor_id: "mon_abc123", limit: 10).call

    assert_requested :get, "https://api.exa.ai/monitors/mon_abc123/runs?limit=10"
    assert_instance_of Exa::Resources::SearchMonitorRunList, result
    run = result.data.first
    assert_instance_of Exa::Resources::SearchMonitorRun, run
    assert_equal "mon_abc123", run.monitor_id
    assert_equal 1200, run.duration_ms
    assert run.finished?
    assert_nil result.next_cursor
  end
end
