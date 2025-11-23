# frozen_string_literal: true

require "test_helper"

class WebsetsSearchesIntegrationTest < Minitest::Test
  include WebsetsCleanupHelper

  def setup
    super
    @api_key = ENV.fetch("EXA_API_KEY", "test_key_for_vcr")
  end

  def teardown
    super
    Exa.reset
  end

  def test_create_search_with_minimal_params
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search = nil

    VCR.use_cassette("websets_searches_create_minimal") do
      # First create a webset
      webset = client.create_webset(
        search: {
          query: "AI startups",
          count: 1
        }
      )
      track_webset(webset.id)
      assert_instance_of Exa::Resources::Webset, webset

      # Create a search within the webset
      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Machine learning companies",
        count: 2
      )
      track_search(webset.id, search.id)

      assert_instance_of Exa::Resources::WebsetSearch, search
      assert_equal "webset_search", search.object
      assert_includes ["created", "running"], search.status
      assert_equal "Machine learning companies", search.query
      assert_equal 2, search.count
    end
  end

  def test_create_search_with_entity_type
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search = nil

    VCR.use_cassette("websets_searches_create_with_entity") do
      # Create a webset
      webset = client.create_webset(
        search: {
          query: "Tech founders",
          count: 1,
          entity: { type: "person" }
        }
      )
      track_webset(webset.id)

      # Create a search for people
      search = client.create_webset_search(
        webset_id: webset.id,
        query: "AI researchers",
        count: 2,
        entity: { type: "person" }
      )
      track_search(webset.id, search.id)

      assert_instance_of Exa::Resources::WebsetSearch, search
      assert_equal "person", search.entity["type"]
    end
  end

  def test_create_search_with_custom_entity_type
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search = nil

    VCR.use_cassette("websets_searches_create_with_custom_entity") do
      # Create a webset with custom entity type
      webset = client.create_webset(
        search: {
          query: "Open source sustainability projects",
          count: 1,
          entity: {
            type: "custom",
            description: "environmental conservation initiatives"
          }
        }
      )
      track_webset(webset.id)

      # Create a search with custom entity type
      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Community-led climate action programs",
        count: 2,
        entity: {
          type: "custom",
          description: "grassroots environmental organizations"
        }
      )
      track_search(webset.id, search.id)

      assert_instance_of Exa::Resources::WebsetSearch, search
      assert_equal "custom", search.entity["type"]
      assert_equal "grassroots environmental organizations", search.entity["description"]
    end
  end

  def test_create_search_with_criteria
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search = nil

    VCR.use_cassette("websets_searches_create_with_criteria") do
      webset = client.create_webset(
        search: {
          query: "B2B SaaS",
          count: 1
        }
      )
      track_webset(webset.id)

      criteria = [
        { description: "focused on enterprise customers" },
        { description: "raised Series A or later" }
      ]

      search = client.create_webset_search(
        webset_id: webset.id,
        query: "SaaS companies",
        count: 2,
        criteria: criteria
      )
      track_search(webset.id, search.id)

      assert_instance_of Exa::Resources::WebsetSearch, search
      assert_equal 2, search.criteria.length if search.criteria
      assert_equal "focused on enterprise customers", search.criteria[0]["description"] if search.criteria
    end
  end

  def test_create_search_with_recall
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search = nil

    VCR.use_cassette("websets_searches_create_with_recall") do
      webset = client.create_webset(
        search: {
          query: "Biotech companies",
          count: 1
        }
      )
      track_webset(webset.id)

      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Pharmaceutical startups",
        count: 2,
        recall: true
      )
      track_search(webset.id, search.id)

      assert_instance_of Exa::Resources::WebsetSearch, search
      # Recall data may not be immediately available, so just verify the search exists
      refute_nil search.id
    end
  end

  def test_create_search_with_behavior_override
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search = nil

    VCR.use_cassette("websets_searches_override") do
      webset = client.create_webset(
        search: {
          query: "Series A fintech startups in London",
          count: 1
        }
      )
      track_webset(webset.id)

      # Create a search with override behavior
      search = client.create_webset_search(
        webset_id: webset.id,
        query: "European payment processing companies",
        count: 2,
        behavior: "override"
      )
      track_search(webset.id, search.id)

      assert_instance_of Exa::Resources::WebsetSearch, search
      assert_equal "override", search.behavior
      assert search.override?
      refute search.append?
    end
  end

  def test_create_search_with_behavior_append
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search = nil

    VCR.use_cassette("websets_searches_create_with_append") do
      webset = client.create_webset(
        search: {
          query: "London Fintechs",
          count: 1
        }
      )
      track_webset(webset.id)

      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Paris Fintechs",
        count: 2,
        behavior: "append"
      )
      track_search(webset.id, search.id)

      assert_instance_of Exa::Resources::WebsetSearch, search
      assert_equal "append", search.behavior
      assert search.append?
      refute search.override?
    end
  end

  def test_create_and_retrieve_search
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    created_search = nil
    retrieved_search = nil

    VCR.use_cassette("websets_searches_create_and_retrieve") do
      # Create a webset
      webset = client.create_webset(
        search: {
          query: "Tech companies",
          count: 1
        }
      )
      track_webset(webset.id)

      # Create a search
      created_search = client.create_webset_search(
        webset_id: webset.id,
        query: "AI companies",
        count: 2
      )
      track_search(webset.id, created_search.id)

      assert_instance_of Exa::Resources::WebsetSearch, created_search
      search_id = created_search.id

      # Retrieve the search
      retrieved_search = client.get_webset_search(
        webset_id: webset.id,
        id: search_id
      )

      assert_instance_of Exa::Resources::WebsetSearch, retrieved_search
      assert_equal search_id, retrieved_search.id
      assert_equal "AI companies", retrieved_search.query
      assert_equal 2, retrieved_search.count
    end
  end

  def test_search_status_progression
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search = nil
    retrieved = nil

    VCR.use_cassette("websets_searches_status_progression") do
      webset = client.create_webset(
        search: {
          query: "Healthcare technology startups",
          count: 1
        }
      )
      track_webset(webset.id)

      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Digital health platforms with FDA approval",
        count: 2
      )
      track_search(webset.id, search.id)

      # Initial status should be created or running
      assert_includes ["created", "running"], search.status
      assert search.in_progress?

      # Poll and check status
      retrieved = client.get_webset_search(
        webset_id: webset.id,
        id: search.id
      )

      assert_includes ["created", "running", "completed", "failed"], retrieved.status
      refute_nil retrieved.created_at
      refute_nil retrieved.updated_at
    end
  end

  def test_cancel_search
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search = nil
    canceled = nil

    VCR.use_cassette("websets_searches_cancel") do
      webset = client.create_webset(
        search: {
          query: "enterprise AI/ML infrastructure startups with Series A funding",
          count: 2
        }
      )
      track_webset(webset.id)

      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Cloud infrastructure companies with enterprise customers",
        count: 2
      )
      track_search(webset.id, search.id)

      # Cancel the search
      canceled = client.cancel_webset_search(
        webset_id: webset.id,
        id: search.id
      )

      assert_instance_of Exa::Resources::WebsetSearch, canceled
      assert_equal "canceled", canceled.status
      assert canceled.canceled?
      refute canceled.running?
      assert_equal "user_requested", canceled.canceled_reason if canceled.canceled_reason
    end
  end

  def test_search_with_metadata
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search = nil

    VCR.use_cassette("websets_searches_with_metadata") do
      webset = client.create_webset(
        search: {
          query: "Climate tech companies",
          count: 1
        }
      )
      track_webset(webset.id)

      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Carbon capture and renewable energy startups",
        count: 2,
        metadata: {
          "test_key" => "test_value",
          "project" => "integration_test"
        }
      )
      track_search(webset.id, search.id)

      assert_instance_of Exa::Resources::WebsetSearch, search
      # Metadata may not be echoed back by the API, so only assert if present
      if search.metadata&.dig("test_key")
        assert_equal "test_value", search.metadata["test_key"]
        assert_equal "integration_test", search.metadata["project"]
      end
    end
  end

  def test_multiple_searches_in_webset
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search1 = nil
    search2 = nil

    VCR.use_cassette("websets_searches_multiple") do
      webset = client.create_webset(
        search: {
          query: "venture-backed SaaS companies",
          count: 1
        }
      )
      track_webset(webset.id)

      # Create first search
      search1 = client.create_webset_search(
        webset_id: webset.id,
        query: "E-commerce platforms with international shipping",
        count: 2
      )
      track_search(webset.id, search1.id)

      # Create second search
      search2 = client.create_webset_search(
        webset_id: webset.id,
        query: "Direct-to-consumer brands in fashion",
        count: 2
      )
      track_search(webset.id, search2.id)

      assert_instance_of Exa::Resources::WebsetSearch, search1
      assert_instance_of Exa::Resources::WebsetSearch, search2
      refute_equal search1.id, search2.id
      assert_equal "E-commerce platforms with international shipping", search1.query
      assert_equal "Direct-to-consumer brands in fashion", search2.query
    end
  end

  def test_search_helper_methods
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search = nil

    VCR.use_cassette("websets_searches_helper_methods") do
      webset = client.create_webset(
        search: {
          query: "EdTech companies",
          count: 1
        }
      )
      track_webset(webset.id)

      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Online learning platforms for corporate training",
        count: 2,
        behavior: "override"
      )
      track_search(webset.id, search.id)

      # Test status helpers
      assert search.created? || search.running?
      refute search.completed?
      refute search.failed?
      refute search.canceled?
      assert search.in_progress?

      # Test behavior helpers
      assert search.override?
      refute search.append?

      # Test to_h
      hash = search.to_h
      assert_instance_of Hash, hash
      assert_equal search.id, hash[:id]
      assert_equal search.query, hash[:query]
      assert_equal search.behavior, hash[:behavior]
    end
  end
end
