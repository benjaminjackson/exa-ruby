# frozen_string_literal: true

require "test_helper"

class CancelWebsetIntegrationTest < Minitest::Test
  include WebsetsCleanupHelper

  def setup
    skip_unless_integration_enabled
    super
    @api_key = ENV.fetch("EXA_API_KEY", "test_key_for_vcr")
  end

  def teardown
    super
    Exa.reset
  end

  def test_cancel_webset_with_running_operations
    VCR.use_cassette("cancel_webset_running") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset with a search that will take time to process
      webset = client.create_webset(
        search: {
          query: "AI/ML infrastructure startups with Series A funding",
          count: 5
        }
      )
      track_webset(webset.id)

      assert_instance_of Exa::Resources::Webset, webset

      # Cancel the webset operations
      canceled = client.cancel_webset(webset.id)

      assert_instance_of Exa::Resources::Webset, canceled
      assert_equal webset.id, canceled.id
      assert_equal "webset", canceled.object
      # Status should reflect cancellation
      assert_includes ["idle", "pending", "running", "cancelled"], canceled.status
    end
  end

  def test_cancel_webset_with_enrichments
    VCR.use_cassette("cancel_webset_with_enrichments") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset with enrichments
      webset = client.create_webset(
        search: {
          query: "Tech startups in San Francisco",
          count: 3
        },
        enrichments: [
          {
            description: "Find the company's primary contact email",
            format: "text"
          }
        ]
      )
      track_webset(webset.id)

      # Track enrichments for cleanup
      webset.enrichments.each { |e| track_enrichment(webset.id, e["id"]) if e["id"] }

      # Cancel all operations
      canceled = client.cancel_webset(webset.id)

      assert_instance_of Exa::Resources::Webset, canceled
      assert_equal webset.id, canceled.id
    end
  end

  def test_cancel_webset_returns_webset_resource
    VCR.use_cassette("cancel_webset_returns_resource") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset
      webset = client.create_webset(
        search: {
          query: "E-commerce companies in California",
          count: 2
        }
      )
      track_webset(webset.id)

      # Cancel it
      result = client.cancel_webset(webset.id)

      assert_instance_of Exa::Resources::Webset, result
      assert_equal webset.id, result.id
      assert_equal "webset", result.object
      refute_nil result.created_at
      refute_nil result.updated_at
    end
  end

  def test_cancel_already_idle_webset
    VCR.use_cassette("cancel_idle_webset") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset with minimal work
      webset = client.create_webset(
        search: {
          query: "AI startups",
          count: 1
        }
      )
      track_webset(webset.id)

      # Wait for it to complete
      completed = wait_for_webset_completion(client, webset.id)
      assert completed.idle?

      # Try to cancel it (should succeed but have no effect)
      result = client.cancel_webset(webset.id)

      assert_instance_of Exa::Resources::Webset, result
      assert_equal webset.id, result.id
    end
  end
end
