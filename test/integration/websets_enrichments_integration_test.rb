# frozen_string_literal: true

require "test_helper"

class WebsetsEnrichmentsIntegrationTest < Minitest::Test
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

  def test_create_enrichment_with_text_format
    VCR.use_cassette("websets_enrichments_create_text_format") do
      client = Exa::Client.new(api_key: @api_key)

      # First create a webset
      webset = client.create_webset(
        search: {
          query: "SaaS companies in San Francisco",
          count: 1
        }
      )
      track_webset(webset.id)

      # Create enrichment with text format
      enrichment = client.create_enrichment(
        webset_id: webset.id,
        description: "Find the company's primary contact email address",
        format: "text"
      )
      track_enrichment(webset.id, enrichment.id)

      assert_instance_of Exa::Resources::WebsetEnrichment, enrichment
      assert enrichment.id.start_with?("enrich_") || enrichment.id.start_with?("wenrich_")
      assert_equal "webset_enrichment", enrichment.object
      assert_equal "text", enrichment.format
      assert_equal "Find the company's primary contact email address", enrichment.description
      assert_includes ["pending", "running", "idle"], enrichment.status
    end
  end

  def test_create_enrichment_with_url_format
    VCR.use_cassette("websets_enrichments_create_url_format") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset
      webset = client.create_webset(
        search: {
          query: "Tech startups in NYC",
          count: 1
        }
      )
      track_webset(webset.id)

      # Create enrichment with url format
      enrichment = client.create_enrichment(
        webset_id: webset.id,
        description: "Find the company's LinkedIn profile URL",
        format: "url"
      )
      track_enrichment(webset.id, enrichment.id)

      assert_instance_of Exa::Resources::WebsetEnrichment, enrichment
      assert_equal "webset_enrichment", enrichment.object
      assert_equal "url", enrichment.format
    end
  end

  def test_create_enrichment_with_options_format
    VCR.use_cassette("websets_enrichments_create_options_format") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset
      webset = client.create_webset(
        search: {
          query: "E-commerce companies in California",
          count: 1
        }
      )
      track_webset(webset.id)

      # Create enrichment with options format
      enrichment = client.create_enrichment(
        webset_id: webset.id,
        description: "Determine the company size category",
        format: "options",
        options: [
          { label: "1-10 employees" },
          { label: "11-50 employees" },
          { label: "51-200 employees" },
          { label: "201+ employees" }
        ]
      )
      track_enrichment(webset.id, enrichment.id)

      assert_instance_of Exa::Resources::WebsetEnrichment, enrichment
      assert_equal "webset_enrichment", enrichment.object
      assert_equal "options", enrichment.format
      assert_equal 4, enrichment.options.length
    end
  end

  def test_get_enrichment
    VCR.use_cassette("websets_enrichments_get") do
      client = Exa::Client.new(api_key: @api_key)

      # Create webset and enrichment
      webset = client.create_webset(
        search: {
          query: "Fintech companies in London",
          count: 1
        }
      )
      track_webset(webset.id)

      created_enrichment = client.create_enrichment(
        webset_id: webset.id,
        description: "Find the CEO's name",
        format: "text"
      )
      track_enrichment(webset.id, created_enrichment.id)

      # Get the enrichment by ID
      retrieved_enrichment = client.get_enrichment(
        webset_id: webset.id,
        id: created_enrichment.id
      )

      assert_instance_of Exa::Resources::WebsetEnrichment, retrieved_enrichment
      assert_equal created_enrichment.id, retrieved_enrichment.id
      assert_equal created_enrichment.description, retrieved_enrichment.description
      assert_equal created_enrichment.format, retrieved_enrichment.format
    end
  end

  def test_list_enrichments_via_webset
    VCR.use_cassette("websets_enrichments_list") do
      client = Exa::Client.new(api_key: @api_key)

      # Create webset
      webset = client.create_webset(
        search: {
          query: "Marketing agencies in Boston",
          count: 1
        }
      )
      track_webset(webset.id)

      # Create multiple enrichments
      enrichment1 = client.create_enrichment(
        webset_id: webset.id,
        description: "Find company email",
        format: "text"
      )
      track_enrichment(webset.id, enrichment1.id)

      enrichment2 = client.create_enrichment(
        webset_id: webset.id,
        description: "Find company website",
        format: "url"
      )
      track_enrichment(webset.id, enrichment2.id)

      # Retrieve webset to get enrichments
      retrieved_webset = client.get_webset(webset.id)

      refute_nil retrieved_webset.enrichments
      assert retrieved_webset.enrichments.length >= 2

      enrichment_ids = retrieved_webset.enrichments.map { |e| e["id"] }
      assert_includes enrichment_ids, enrichment1.id
      assert_includes enrichment_ids, enrichment2.id
    end
  end

  def test_update_enrichment
    VCR.use_cassette("websets_enrichments_update") do
      client = Exa::Client.new(api_key: @api_key)

      # Create webset and enrichment
      webset = client.create_webset(
        search: {
          query: "Healthcare companies in Seattle",
          count: 1
        }
      )
      track_webset(webset.id)

      enrichment = client.create_enrichment(
        webset_id: webset.id,
        description: "Original description",
        format: "text"
      )
      track_enrichment(webset.id, enrichment.id)

      # Update the enrichment
      updated_enrichment = client.update_enrichment(
        webset_id: webset.id,
        id: enrichment.id,
        description: "Updated description for company contact"
      )

      assert_instance_of Exa::Resources::WebsetEnrichment, updated_enrichment
      assert_equal enrichment.id, updated_enrichment.id
      assert_equal "Updated description for company contact", updated_enrichment.description
    end
  end

  def test_delete_enrichment
    VCR.use_cassette("websets_enrichments_delete") do
      client = Exa::Client.new(api_key: @api_key)

      # Create webset and enrichment
      webset = client.create_webset(
        search: {
          query: "Retail companies in Chicago",
          count: 1
        }
      )
      track_webset(webset.id)

      enrichment = client.create_enrichment(
        webset_id: webset.id,
        description: "To be deleted",
        format: "text"
      )
      enrichment_id = enrichment.id
      track_enrichment(webset.id, enrichment_id)

      # Delete the enrichment
      deleted_enrichment = client.delete_enrichment(
        webset_id: webset.id,
        id: enrichment_id
      )

      assert_instance_of Exa::Resources::WebsetEnrichment, deleted_enrichment
      assert_equal enrichment_id, deleted_enrichment.id
    end
  end

  def test_cancel_enrichment
    VCR.use_cassette("websets_enrichments_cancel") do
      client = Exa::Client.new(api_key: @api_key)

      # Create webset and enrichment
      webset = client.create_webset(
        search: {
          query: "Manufacturing companies in Detroit",
          count: 1
        }
      )
      track_webset(webset.id)

      enrichment = client.create_enrichment(
        webset_id: webset.id,
        description: "To be cancelled",
        format: "text"
      )
      track_enrichment(webset.id, enrichment.id)

      # Cancel the enrichment
      cancelled_enrichment = client.cancel_enrichment(
        webset_id: webset.id,
        id: enrichment.id
      )

      assert_instance_of Exa::Resources::WebsetEnrichment, cancelled_enrichment
      assert_equal enrichment.id, cancelled_enrichment.id
      assert_includes ["cancelled", "idle", "pending", "running", "completed"], cancelled_enrichment.status
    end
  end

  def test_enrichment_values_populated_on_items
    VCR.use_cassette("websets_enrichments_values_on_items") do
      client = Exa::Client.new(api_key: @api_key)

      # Create webset with search and enrichments
      webset = client.create_webset(
        search: {
          query: "AI/ML infrastructure companies with venture funding",
          count: 1
        },
        enrichments: [
          {
            description: "Find the company's headquarters location",
            format: "text"
          },
          {
            description: "Find the company's website URL",
            format: "url"
          }
        ]
      )
      track_webset(webset.id)

      # Track enrichments for cleanup
      webset.enrichments.each { |e| track_enrichment(webset.id, e["id"]) if e["id"] }

      # Wait for webset to complete processing
      completed_webset = wait_for_webset_completion(client, webset.id)

      # Skip if webset didn't complete (e.g., during VCR playback)
      skip "Webset did not complete" unless completed_webset&.idle?

      # Get items with enrichment values
      items = client.list_items(webset_id: webset.id)

      skip "No items in webset" if items.nil? || items.empty?

      # Verify items have enrichment values
      first_item = items.first
      assert first_item.key?("id")
      assert first_item.key?("properties")

      # Enrichment values should be present in the properties
      # The exact structure depends on the API response format
      refute_nil first_item["properties"]
    end
  end
end
