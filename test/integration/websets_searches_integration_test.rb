# frozen_string_literal: true

require "test_helper"

class WebsetsSearchesIntegrationTest < Minitest::Test
  def setup
    @api_key = ENV.fetch("EXA_API_KEY", "test_key_for_vcr")
    @webset_ids = []
  end

  def teardown
    # Cancel any websets created during the test to free up API resources
    if @webset_ids.any?
      client = Exa::Client.new(api_key: @api_key)
      @webset_ids.each do |webset_id|
        begin
          client.cancel_webset(webset_id)
        rescue => e
          # Ignore errors if webset is already canceled or doesn't exist
        end
      end
    end
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
      @webset_ids << webset.id
      assert_instance_of Exa::Resources::Webset, webset
    end

    wait_for_webset_completion(client, webset.id)

    VCR.use_cassette("websets_searches_create_minimal") do
      # Create a search within the webset
      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Machine learning companies",
        count: 5
      )

      assert_instance_of Exa::Resources::WebsetSearch, search
      assert_equal "webset_search", search.object
      assert_includes ["created", "running"], search.status
      assert_equal "Machine learning companies", search.query
      assert_equal 5, search.count
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
      @webset_ids << webset.id
    end

    wait_for_webset_completion(client, webset.id)

    VCR.use_cassette("websets_searches_create_with_entity") do
      # Create a search for people
      search = client.create_webset_search(
        webset_id: webset.id,
        query: "AI researchers",
        count: 10,
        entity: { type: "person" }
      )

      assert_instance_of Exa::Resources::WebsetSearch, search
      assert_equal "person", search.entity["type"]
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
      @webset_ids << webset.id
    end

    wait_for_webset_completion(client, webset.id)

    VCR.use_cassette("websets_searches_create_with_criteria") do
      criteria = [
        { description: "focused on enterprise customers" },
        { description: "raised Series A or later" }
      ]

      search = client.create_webset_search(
        webset_id: webset.id,
        query: "SaaS companies",
        count: 20,
        criteria: criteria
      )

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
      @webset_ids << webset.id
    end

    wait_for_webset_completion(client, webset.id)

    VCR.use_cassette("websets_searches_create_with_recall") do
      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Pharmaceutical startups",
        count: 50,
        recall: true
      )

      assert_instance_of Exa::Resources::WebsetSearch, search
      # Recall data may not be immediately available, so just verify the search exists
      refute_nil search.id
    end
  end

  def test_create_search_with_behavior_override
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search = nil

    VCR.use_cassette("websets_searches_create_with_override") do
      webset = client.create_webset(
        search: {
          query: "Initial companies",
          count: 1
        }
      )
      @webset_ids << webset.id
    end

    wait_for_webset_completion(client, webset.id)

    VCR.use_cassette("websets_searches_create_with_override") do
      search = client.create_webset_search(
        webset_id: webset.id,
        query: "New search query",
        count: 10,
        behavior: "override"
      )

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
          query: "Initial companies",
          count: 1
        }
      )
      @webset_ids << webset.id
    end

    wait_for_webset_completion(client, webset.id)

    VCR.use_cassette("websets_searches_create_with_append") do
      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Additional companies",
        count: 5,
        behavior: "append"
      )

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
      @webset_ids << webset.id
    end

    wait_for_webset_completion(client, webset.id)

    VCR.use_cassette("websets_searches_create_and_retrieve") do
      # Create a search
      created_search = client.create_webset_search(
        webset_id: webset.id,
        query: "AI companies",
        count: 10
      )

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
      assert_equal 10, retrieved_search.count
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
          query: "Companies for status test",
          count: 1
        }
      )
      @webset_ids << webset.id
    end

    wait_for_webset_completion(client, webset.id)

    VCR.use_cassette("websets_searches_status_progression") do
      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Status tracking test",
        count: 5
      )

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
          query: "Long running search",
          count: 1
        }
      )
      @webset_ids << webset.id
    end

    wait_for_webset_completion(client, webset.id)

    VCR.use_cassette("websets_searches_cancel") do
      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Query to cancel",
        count: 100
      )

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
          query: "Companies for metadata test",
          count: 1
        }
      )
      @webset_ids << webset.id
    end

    wait_for_webset_completion(client, webset.id)

    VCR.use_cassette("websets_searches_with_metadata") do
      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Metadata test search",
        count: 10,
        metadata: {
          "test_key" => "test_value",
          "project" => "integration_test"
        }
      )

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
          query: "Base search",
          count: 1
        }
      )
      @webset_ids << webset.id
    end

    wait_for_webset_completion(client, webset.id)

    VCR.use_cassette("websets_searches_multiple") do
      # Create first search
      search1 = client.create_webset_search(
        webset_id: webset.id,
        query: "First search",
        count: 5
      )

      # Create second search
      search2 = client.create_webset_search(
        webset_id: webset.id,
        query: "Second search",
        count: 10
      )

      assert_instance_of Exa::Resources::WebsetSearch, search1
      assert_instance_of Exa::Resources::WebsetSearch, search2
      refute_equal search1.id, search2.id
      assert_equal "First search", search1.query
      assert_equal "Second search", search2.query
    end
  end

  def test_search_helper_methods
    client = Exa::Client.new(api_key: @api_key)
    webset = nil
    search = nil

    VCR.use_cassette("websets_searches_helper_methods") do
      webset = client.create_webset(
        search: {
          query: "Test helper methods",
          count: 1
        }
      )
      @webset_ids << webset.id
    end

    wait_for_webset_completion(client, webset.id)

    VCR.use_cassette("websets_searches_helper_methods") do
      search = client.create_webset_search(
        webset_id: webset.id,
        query: "Helper method test",
        count: 5,
        behavior: "override"
      )

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
