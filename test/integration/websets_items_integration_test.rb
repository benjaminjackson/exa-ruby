# frozen_string_literal: true

require "test_helper"

class WebsetsItemsIntegrationTest < Minitest::Test
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

  def test_get_item
    VCR.use_cassette("websets_get_item") do
      client = Exa::Client.new(api_key: @api_key)

      # First create a webset with items
      webset = client.create_webset(
        search: {
          query: "AI/ML infrastructure startups with Series A funding",
          count: 1
        }
      )
      track_webset(webset.id)

      # Wait for webset to complete and have items
      completed = wait_for_webset_completion(client, webset.id)
      assert completed.idle?

      # Get the webset with items expanded
      retrieved_webset = client.get_webset(webset.id, expand: ["items"])

      skip "No items in webset" if retrieved_webset.items.nil? || retrieved_webset.items.empty?

      item_id = retrieved_webset.items.first["id"]

      # Get the specific item
      item = client.get_item(webset_id: webset.id, id: item_id)

      assert_instance_of Hash, item
      assert_equal item_id, item["id"]
      assert item.key?("properties")
      refute_nil item["properties"]["url"]
    end
  end

  def test_delete_item
    VCR.use_cassette("websets_delete_item") do
      client = Exa::Client.new(api_key: @api_key)

      # First create a webset with items
      webset = client.create_webset(
        search: {
          query: "B2B SaaS companies with recent funding rounds",
          count: 1
        }
      )
      track_webset(webset.id)

      # Wait for webset to complete and have items
      completed = wait_for_webset_completion(client, webset.id)
      assert completed.idle?

      # Get the webset with items expanded
      retrieved_webset = client.get_webset(webset.id, expand: ["items"])

      skip "No items in webset" if retrieved_webset.items.nil? || retrieved_webset.items.empty?

      item_id = retrieved_webset.items.first["id"]

      # Delete the item
      result = client.delete_item(webset_id: webset.id, id: item_id)

      assert_equal true, result
    end
  end

  def test_list_items
    VCR.use_cassette("websets_list_items") do
      client = Exa::Client.new(api_key: @api_key)

      # First create a webset with items
      webset = client.create_webset(
        search: {
          query: "Cybersecurity companies with enterprise customers",
          count: 2
        }
      )
      track_webset(webset.id)

      # Wait for webset to complete and have items
      completed = wait_for_webset_completion(client, webset.id)
      assert completed.idle?

      # List all items in the webset
      items = client.list_items(webset_id: webset.id)

      assert_instance_of Array, items
      refute_empty items
      items.each do |item|
        assert item.key?("id")
        # Items have a nested properties structure with the URL
        assert item.key?("properties")
        assert item["properties"].key?("url")
      end
    end
  end

  def test_get_webset_with_expand_items
    VCR.use_cassette("websets_get_with_expand_items") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset with items
      webset = client.create_webset(
        search: {
          query: "Enterprise SaaS companies with AI features",
          count: 2
        }
      )
      track_webset(webset.id)

      # Wait for webset to complete and have items
      completed = wait_for_webset_completion(client, webset.id)
      assert completed.idle?

      # Get webset with expand items parameter
      retrieved = client.get_webset(webset.id, expand: ["items"])

      assert_instance_of Exa::Resources::Webset, retrieved
      assert_equal webset.id, retrieved.id
      refute_nil retrieved.items, "Items should be included when expand parameter is used"
      assert_instance_of Array, retrieved.items
    end
  end
end
