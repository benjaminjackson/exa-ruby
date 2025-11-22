# frozen_string_literal: true

require "test_helper"

class WebsetsIntegrationTest < Minitest::Test
  def setup
    @api_key = ENV.fetch("EXA_API_KEY", "test_key_for_vcr")
  end

  def teardown
    Exa.reset
  end

  def test_create_webset_with_search
    VCR.use_cassette("websets_create_with_search") do
      client = Exa::Client.new(api_key: @api_key)

      result = client.create_webset(
        search: {
          query: "AI companies in San Francisco with 10-50 employees",
          count: 1
        },
        metadata: {
          "test" => "integration_test",
          "created_by" => "exa-ruby"
        }
      )

      assert_instance_of Exa::Resources::Webset, result
      assert result.id.start_with?("ws_") || result.id.start_with?("webset_")
      assert_equal "webset", result.object
      assert_includes ["idle", "pending", "running"], result.status
      refute_nil result.searches
      refute_nil result.created_at
      refute_nil result.updated_at
    end
  end

  def test_create_webset_with_external_id
    VCR.use_cassette("websets_create_with_external_id") do
      client = Exa::Client.new(api_key: @api_key)

      # Use static external_id for VCR to work properly
      external_id = "test-external-static-id"

      result = client.create_webset(
        search: {
          query: "SaaS companies in Europe",
          count: 1
        },
        externalId: external_id
      )

      assert_instance_of Exa::Resources::Webset, result
      assert_equal external_id, result.external_id
      assert_equal "webset", result.object
    end
  end

  def test_create_webset_with_criteria
    VCR.use_cassette("websets_create_with_criteria") do
      client = Exa::Client.new(api_key: @api_key)

      result = client.create_webset(
        search: {
          query: "Marketing agencies in the US",
          count: 1,
          criteria: [
            { description: "focused on consumer products" },
            { description: "at least 50 employees" }
          ]
        }
      )

      assert_instance_of Exa::Resources::Webset, result
      refute_empty result.searches

      # Wait for webset to complete processing
      completed = wait_for_webset_completion(client, result.id)
      assert completed.idle?
    end
  end

  def test_create_webset_with_enrichments
    VCR.use_cassette("websets_create_with_enrichments") do
      client = Exa::Client.new(api_key: @api_key)

      result = client.create_webset(
        search: {
          query: "Tech startups in NYC",
          count: 1
        },
        enrichments: [
          {
            description: "Find the company's primary contact email address",
            format: "text"
          },
          {
            description: "Determine the company size category",
            format: "options",
            options: [
              { label: "1-10 employees" },
              { label: "11-50 employees" },
              { label: "51-200 employees" },
              { label: "201+ employees" }
            ]
          }
        ]
      )

      assert_instance_of Exa::Resources::Webset, result
      refute_empty result.enrichments
      assert_equal 2, result.enrichments.length

      # Wait for webset to complete processing
      completed = wait_for_webset_completion(client, result.id)
      assert completed.idle?
    end
  end

  def test_create_webset_with_entity_type
    VCR.use_cassette("websets_create_with_entity") do
      client = Exa::Client.new(api_key: @api_key)

      result = client.create_webset(
        search: {
          query: "CTOs at AI companies",
          count: 1,
          entity: { type: "person" }
        }
      )

      assert_instance_of Exa::Resources::Webset, result
      assert_equal "webset", result.object
    end
  end

  def test_create_and_retrieve_webset
    VCR.use_cassette("websets_create_and_retrieve") do
      client = Exa::Client.new(api_key: @api_key)

      # Create webset
      created = client.create_webset(
        search: {
          query: "Fintech companies in London",
          count: 1
        },
        metadata: {
          "purpose" => "integration_test"
        }
      )

      assert_instance_of Exa::Resources::Webset, created
      webset_id = created.id

      # Retrieve the same webset
      retrieved = client.get_webset(webset_id)

      assert_instance_of Exa::Resources::Webset, retrieved
      assert_equal webset_id, retrieved.id
      assert_equal created.object, retrieved.object
    end
  end

  def test_create_webset_full_workflow
    VCR.use_cassette("websets_create_full_workflow") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a comprehensive webset
      webset = client.create_webset(
        search: {
          query: "E-commerce companies in California with recent funding",
          count: 1,
          entity: { type: "company" },
          criteria: [
            { description: "raised funding in the last 12 months" },
            { description: "focused on direct-to-consumer products" }
          ]
        },
        enrichments: [
          {
            description: "Extract the most recent funding amount",
            format: "text"
          },
          {
            description: "Find the company's LinkedIn URL",
            format: "url"
          }
        ],
        metadata: {
          "project" => "Q1-2024-research",
          "team" => "growth"
        }
      )

      # Verify creation
      assert_instance_of Exa::Resources::Webset, webset
      assert_equal "webset", webset.object
      refute_empty webset.searches
      assert_equal 2, webset.enrichments.length
      assert_equal "Q1-2024-research", webset.metadata["project"]

      # Wait for webset to complete processing before listing
      completed = wait_for_webset_completion(client, webset.id)
      assert completed.idle?

      # List websets and verify it appears
      list = client.list_websets(limit: 10)
      assert_instance_of Exa::Resources::WebsetCollection, list
      webset_ids = list.data.map { |ws| ws["id"] }
      assert_includes webset_ids, webset.id
    end
  end

  def test_create_webset_with_exclude
    VCR.use_cassette("websets_create_with_exclude") do
      client = Exa::Client.new(api_key: @api_key)

      # First create a webset to exclude from
      existing = client.create_webset(
        search: {
          query: "Tech companies in Seattle",
          count: 1
        }
      )

      # Wait for first webset to complete before using it in exclude
      wait_for_webset_completion(client, existing.id)

      # Create new webset excluding the previous one
      result = client.create_webset(
        search: {
          query: "Tech companies in Pacific Northwest",
          count: 1
        },
        exclude: [
          {
            source: "webset",
            id: existing.id
          }
        ]
      )

      assert_instance_of Exa::Resources::Webset, result
      refute_empty result.excludes if result.excludes

      # Wait for second webset to complete
      completed = wait_for_webset_completion(client, result.id)
      assert completed.idle?
    end
  end
end
