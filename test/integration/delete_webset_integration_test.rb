# frozen_string_literal: true

require "test_helper"

class DeleteWebsetIntegrationTest < Minitest::Test
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

  def test_delete_webset
    VCR.use_cassette("delete_webset_basic") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset to delete
      webset = client.create_webset(
        search: {
          query: "AI companies in San Francisco",
          count: 1
        }
      )
      webset_id = webset.id
      track_webset(webset_id)

      assert_instance_of Exa::Resources::Webset, webset

      # Delete the webset
      result = client.delete_webset(webset_id)

      assert_instance_of Exa::Resources::Webset, result
      assert_equal webset_id, result.id
      assert_equal "webset", result.object
    end
  end

  def test_delete_webset_with_metadata
    VCR.use_cassette("delete_webset_with_metadata") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset with metadata
      webset = client.create_webset(
        search: {
          query: "Fintech startups in New York",
          count: 1
        },
        metadata: {
          "test" => "delete_test",
          "purpose" => "integration_testing"
        }
      )
      track_webset(webset.id)

      # Delete it
      deleted = client.delete_webset(webset.id)

      assert_instance_of Exa::Resources::Webset, deleted
      assert_equal webset.id, deleted.id
      refute_nil deleted.metadata
    end
  end

  def test_delete_webset_with_enrichments
    VCR.use_cassette("delete_webset_with_enrichments") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset with enrichments
      webset = client.create_webset(
        search: {
          query: "E-commerce companies in Europe",
          count: 1
        },
        enrichments: [
          {
            description: "Find company website",
            format: "url"
          }
        ]
      )
      track_webset(webset.id)

      # Track enrichments for cleanup
      webset.enrichments.each { |e| track_enrichment(webset.id, e["id"]) if e["id"] }

      # Delete the webset
      result = client.delete_webset(webset.id)

      assert_instance_of Exa::Resources::Webset, result
      assert_equal webset.id, result.id
    end
  end

  def test_delete_webset_returns_deleted_resource
    VCR.use_cassette("delete_webset_returns_deleted_resource") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset
      webset = client.create_webset(
        search: {
          query: "Healthcare tech startups",
          count: 1
        }
      )
      track_webset(webset.id)

      # Delete and verify the returned resource
      deleted = client.delete_webset(webset.id)

      assert_instance_of Exa::Resources::Webset, deleted
      assert_equal webset.id, deleted.id
      assert_equal "webset", deleted.object
      refute_nil deleted.created_at
      refute_nil deleted.updated_at
    end
  end

  def test_delete_webset_with_completed_searches
    VCR.use_cassette("delete_webset_with_completed_searches") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset and wait for it to complete
      webset = client.create_webset(
        search: {
          query: "SaaS companies in Seattle",
          count: 1
        }
      )
      track_webset(webset.id)

      # Wait for completion
      completed = wait_for_webset_completion(client, webset.id)
      assert completed.idle?

      # Delete the completed webset
      result = client.delete_webset(webset.id)

      assert_instance_of Exa::Resources::Webset, result
      assert_equal webset.id, result.id
    end
  end
end
