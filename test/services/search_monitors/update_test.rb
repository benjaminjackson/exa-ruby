require "test_helper"

class SearchMonitorsUpdateTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
    stub_request(:patch, "https://api.exa.ai/monitors/mon_abc123")
      .to_return(
        status: 200,
        body: { id: "mon_abc123", name: "Renamed", status: "paused" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def test_call_patches_monitor
    result = Exa::Services::SearchMonitors::Update.new(@connection, id: "mon_abc123", status: "paused").call

    assert_requested :patch, "https://api.exa.ai/monitors/mon_abc123"
    assert_instance_of Exa::Resources::SearchMonitor, result
    assert result.paused?
  end

  def test_call_sends_null_trigger_to_remove_schedule
    Exa::Services::SearchMonitors::Update.new(@connection, id: "mon_abc123", trigger: nil).call

    assert_requested(:patch, "https://api.exa.ai/monitors/mon_abc123") do |request|
      request.body.include?('"trigger":null')
    end
  end

  def test_call_leaves_out_nil_values_of_keys_the_api_does_not_allow_as_null
    Exa::Services::SearchMonitors::Update.new(@connection, id: "mon_abc123", search: nil, webhook: nil, trigger: nil).call

    assert_requested(:patch, "https://api.exa.ai/monitors/mon_abc123") do |request|
      JSON.parse(request.body) == { "trigger" => nil }
    end
  end

  def test_call_converts_partial_search_and_output_schema
    Exa::Services::SearchMonitors::Update.new(
      @connection,
      id: "mon_abc123",
      search: { num_results: 10 },
      output_schema: { type: "object" }
    ).call

    assert_requested(:patch, "https://api.exa.ai/monitors/mon_abc123") do |request|
      JSON.parse(request.body) == { "search" => { "numResults" => 10 }, "outputSchema" => { "type" => "object" } }
    end
  end
end
