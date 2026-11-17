# frozen_string_literal: true

require "test_helper"

# Runs the Websets monitor commands in the test process with a WebMock stub,
# so each test checks that the command calls the client with the arguments
# it expects and sends one request to the monitor URL.
class Exa::CLI::WebsetsMonitorExeTest < Minitest::Test
  MONITOR_URL = "https://api.exa.ai/websets/v0/monitors/mon_1"

  def monitor_response
    {
      status: 200,
      body: {
        id: "mon_1", object: "monitor", status: "enabled", websetId: "ws_1",
        cadence: { cron: "0 0 * * *", timezone: "UTC" },
        behavior: { type: "search", query: "AI infrastructure startups", count: 25 }
      }.to_json,
      headers: { "Content-Type" => "application/json" }
    }
  end

  def test_monitor_update_sends_patch_with_behavior_count
    stub_request(:patch, MONITOR_URL).to_return(monitor_response)

    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-monitor-update", "mon_1", "--behavior-type", "search",
      "--query", "AI infrastructure startups", "--count", "25", "--api-key", "test_key"
    )

    assert_nil exit_status, stderr
    expected_body = { "behavior" => { "type" => "search", "query" => "AI infrastructure startups", "count" => 25 } }
    assert_requested(:patch, MONITOR_URL, times: 1) do |request|
      assert_equal expected_body, JSON.parse(request.body)
    end
  end

  def test_monitor_get_sends_get_to_monitor_url
    stub_request(:get, MONITOR_URL).to_return(monitor_response)

    _stdout, stderr, exit_status = run_exe_in_process("exa-ai-monitor-get", "mon_1", "--api-key", "test_key")

    assert_nil exit_status, stderr
    assert_requested(:get, MONITOR_URL, times: 1)
  end

  def test_monitor_delete_sends_delete_to_monitor_url
    stub_request(:delete, MONITOR_URL).to_return(monitor_response)

    _stdout, stderr, exit_status = run_exe_in_process("exa-ai-monitor-delete", "mon_1", "--api-key", "test_key")

    assert_nil exit_status, stderr
    assert_requested(:delete, MONITOR_URL, times: 1)
  end
end
