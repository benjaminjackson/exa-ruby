# frozen_string_literal: true

require "test_helper"

# The create response holds a webhook secret that the API returns only once.
# Replace it before the cassette is written.
VCR.configure do |config|
  config.before_record(:scrub_webhook_secret) do |interaction|
    interaction.response.body = interaction.response.body.gsub(/"webhookSecret"\s*:\s*"[^"]*"/, '"webhookSecret":"<WEBHOOK_SECRET>"')
  end
end

class SearchMonitorsIntegrationTest < Minitest::Test
  MONITOR_NAME = "exa-ruby integration test"

  def setup
    skip_unless_integration_enabled
  end

  # Create a manual-only monitor (no trigger, so it never runs a search),
  # then get it, list it, and delete it.
  def test_search_monitor_lifecycle
    VCR.use_cassette("search_monitor_lifecycle", tag: :scrub_webhook_secret) do
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])
      monitor = nil

      begin
        monitor = client.search_monitor_create(
          name: MONITOR_NAME,
          search: { query: "AI/ML infrastructure startups with Series A funding", num_results: 1 },
          webhook: { url: "https://httpbin.org/post" },
          metadata: { "test" => "integration_test" }
        )

        assert_instance_of Exa::Resources::SearchMonitor, monitor
        assert_equal MONITOR_NAME, monitor.name
        assert_nil monitor.trigger
        refute_nil monitor.webhook_secret

        fetched = client.search_monitor_get(monitor.id)
        assert_equal monitor.id, fetched.id
        assert_equal "AI/ML infrastructure startups with Series A funding", fetched.search["query"]

        list = client.search_monitor_list(limit: 5, name: MONITOR_NAME)
        assert_instance_of Exa::Resources::SearchMonitorList, list
        assert_includes list.data.map(&:id), monitor.id
      ensure
        if monitor
          deleted = client.search_monitor_delete(monitor.id)
          assert_equal monitor.id, deleted.id
        end
      end
    end
  end
end
