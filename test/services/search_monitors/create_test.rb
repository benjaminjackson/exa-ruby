require "test_helper"

class SearchMonitorsCreateTest < Minitest::Test
  def setup
    @connection = Exa::Connection.build(api_key: "test_key")
  end

  def monitor_body
    {
      id: "mon_abc123",
      name: "AI funding news",
      status: "active",
      search: { query: "AI/ML infrastructure startups with Series A funding", numResults: 5 },
      trigger: { type: "interval", period: "1d" },
      webhook: { url: "https://example.com/webhooks/exa" },
      outputSchema: nil,
      metadata: { "team" => "research" },
      nextRunAt: "2026-11-17T00:00:00Z",
      createdAt: "2026-11-16T00:00:00Z",
      updatedAt: "2026-11-16T00:00:00Z",
      webhookSecret: "whsec_example"
    }
  end

  def stub_create
    stub_request(:post, "https://api.exa.ai/monitors")
      .to_return(status: 201, body: monitor_body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def test_call_posts_to_monitors
    stub_create

    Exa::Services::SearchMonitors::Create.new(
      @connection,
      search: { query: "AI/ML infrastructure startups with Series A funding" },
      webhook: { url: "https://example.com/webhooks/exa" }
    ).call

    assert_requested :post, "https://api.exa.ai/monitors"
  end

  def test_call_converts_search_keys_and_output_schema_but_not_metadata_values
    stub_create

    Exa::Services::SearchMonitors::Create.new(
      @connection,
      search: { query: "AI/ML infrastructure startups with Series A funding", num_results: 5, include_domains: ["techcrunch.com"] },
      webhook: { url: "https://example.com/webhooks/exa", events: ["monitor.run.completed"] },
      trigger: { type: "interval", period: "1d" },
      output_schema: { type: "object", properties: { company_name: { type: "string" } } },
      metadata: { "team_name" => "research" },
      name: "AI funding news"
    ).call

    expected = {
      search: { query: "AI/ML infrastructure startups with Series A funding", numResults: 5, includeDomains: ["techcrunch.com"] },
      webhook: { url: "https://example.com/webhooks/exa", events: ["monitor.run.completed"] },
      trigger: { type: "interval", period: "1d" },
      outputSchema: { type: "object", properties: { company_name: { type: "string" } } },
      metadata: { team_name: "research" },
      name: "AI funding news"
    }
    assert_requested(:post, "https://api.exa.ai/monitors") do |request|
      JSON.parse(request.body, symbolize_names: true) == expected
    end
  end

  def test_call_converts_nested_contents_keys_in_search
    stub_create

    Exa::Services::SearchMonitors::Create.new(
      @connection,
      search: {
        query: "AI/ML infrastructure startups with Series A funding",
        contents: { max_age_hours: 1, text: { max_characters: 500 } }
      },
      webhook: { url: "https://example.com/webhooks/exa" }
    ).call

    assert_requested(:post, "https://api.exa.ai/monitors") do |request|
      contents = JSON.parse(request.body)["search"]["contents"]
      contents["maxAgeHours"] == 1 && contents["text"]["maxCharacters"] == 500
    end
  end

  def test_call_returns_search_monitor_with_webhook_secret
    stub_create

    result = Exa::Services::SearchMonitors::Create.new(
      @connection,
      search: { query: "AI/ML infrastructure startups with Series A funding" },
      webhook: { url: "https://example.com/webhooks/exa" }
    ).call

    assert_instance_of Exa::Resources::SearchMonitor, result
    assert_equal "mon_abc123", result.id
    assert_equal "whsec_example", result.webhook_secret
    assert_equal "2026-11-17T00:00:00Z", result.next_run_at
    assert result.active?
  end
end
