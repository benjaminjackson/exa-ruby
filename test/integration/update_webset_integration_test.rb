# frozen_string_literal: true

require "test_helper"

class UpdateWebsetIntegrationTest < Minitest::Test
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

  def test_update_webset_metadata
    VCR.use_cassette("update_webset_metadata") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset first
      webset = client.create_webset(
        search: {
          query: "AI startups in Silicon Valley",
          count: 1
        },
        metadata: {
          "original_key" => "original_value",
          "project" => "initial_project"
        }
      )
      track_webset(webset.id)

      assert_instance_of Exa::Resources::Webset, webset
      assert_equal "original_value", webset.metadata["original_key"]

      # Update the webset metadata
      updated = client.update_webset(
        webset.id,
        metadata: {
          "original_key" => "updated_value",
          "project" => "updated_project",
          "new_key" => "new_value"
        }
      )

      assert_instance_of Exa::Resources::Webset, updated
      assert_equal webset.id, updated.id
      assert_equal "updated_value", updated.metadata["original_key"]
      assert_equal "updated_project", updated.metadata["project"]
      assert_equal "new_value", updated.metadata["new_key"]
    end
  end

  def test_update_webset_partial_metadata
    VCR.use_cassette("update_webset_partial_metadata") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset
      webset = client.create_webset(
        search: {
          query: "Fintech companies in London",
          count: 1
        },
        metadata: {
          "team" => "research",
          "quarter" => "Q1"
        }
      )
      track_webset(webset.id)

      # Update with additional metadata
      updated = client.update_webset(
        webset.id,
        metadata: {
          "team" => "research",
          "quarter" => "Q2",
          "year" => "2025"
        }
      )

      assert_instance_of Exa::Resources::Webset, updated
      assert_equal "research", updated.metadata["team"]
      assert_equal "Q2", updated.metadata["quarter"]
      assert_equal "2025", updated.metadata["year"]
    end
  end

  def test_update_webset_returns_updated_resource
    VCR.use_cassette("update_webset_returns_updated_resource") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a webset
      webset = client.create_webset(
        search: {
          query: "SaaS companies in Europe",
          count: 1
        }
      )
      track_webset(webset.id)

      # Update it
      updated = client.update_webset(
        webset.id,
        metadata: {
          "updated" => "true"
        }
      )

      assert_instance_of Exa::Resources::Webset, updated
      assert_equal webset.id, updated.id
      assert_equal "webset", updated.object
      assert_equal "true", updated.metadata["updated"]
    end
  end
end
