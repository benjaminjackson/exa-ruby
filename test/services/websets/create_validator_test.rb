# frozen_string_literal: true

require "test_helper"

class WebsetsCreateValidatorTest < Minitest::Test
  def test_validates_successfully_with_minimal_search
    params = {
      search: {
        query: "test query",
        count: 10
      }
    }

    # Should not raise
    Exa::Services::Websets::CreateValidator.validate!(params)
  end

  def test_validates_successfully_with_import_only
    params = {
      import: [{
        source: "import",
        id: "import_123"
      }]
    }

    # Should not raise
    Exa::Services::Websets::CreateValidator.validate!(params)
  end

  def test_raises_when_missing_search_and_import
    params = {}

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/:search or :import/i, error.message)
  end

  def test_raises_when_search_missing_query
    params = {
      search: { count: 10 }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/query.*required/i, error.message)
  end

  def test_raises_when_query_is_empty
    params = {
      search: { query: "   ", count: 10 }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/cannot be empty/i, error.message)
  end

  def test_raises_when_query_exceeds_max_length
    params = {
      search: { query: "a" * 5001, count: 10 }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/5000 characters/i, error.message)
  end

  def test_raises_when_count_is_not_positive
    params = {
      search: { query: "test", count: 0 }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/positive integer/i, error.message)
  end

  def test_validates_valid_entity_types
    %w[company person article research_paper].each do |entity_type|
      params = {
        search: {
          query: "test",
          count: 10,
          entity: { type: entity_type }
        }
      }

      # Should not raise
      Exa::Services::Websets::CreateValidator.validate!(params)
    end
  end

  def test_raises_when_entity_type_invalid
    params = {
      search: {
        query: "test",
        count: 10,
        entity: { type: "invalid_type" }
      }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/must be one of/i, error.message)
  end

  def test_validates_custom_entity_with_description
    params = {
      search: {
        query: "test",
        count: 10,
        entity: {
          type: "custom",
          description: "research grants"
        }
      }
    }

    # Should not raise
    Exa::Services::Websets::CreateValidator.validate!(params)
  end

  def test_raises_when_custom_entity_missing_description
    params = {
      search: {
        query: "test",
        count: 10,
        entity: { type: "custom" }
      }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/description.*required/i, error.message)
  end

  def test_validates_criteria_array
    params = {
      search: {
        query: "test",
        count: 10,
        criteria: [
          { description: "first criterion" },
          { description: "second criterion" }
        ]
      }
    }

    # Should not raise
    Exa::Services::Websets::CreateValidator.validate!(params)
  end

  def test_raises_when_criteria_exceeds_max_items
    params = {
      search: {
        query: "test",
        count: 10,
        criteria: [
          { description: "1" },
          { description: "2" },
          { description: "3" },
          { description: "4" },
          { description: "5" },
          { description: "6" }
        ]
      }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/5 items/i, error.message)
  end

  def test_raises_when_criterion_missing_description
    params = {
      search: {
        query: "test",
        count: 10,
        criteria: [{ other_field: "value" }]
      }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/description.*required/i, error.message)
  end

  def test_validates_enrichments
    params = {
      search: { query: "test", count: 10 },
      enrichments: [
        {
          description: "Find email addresses",
          format: "text"
        }
      ]
    }

    # Should not raise
    Exa::Services::Websets::CreateValidator.validate!(params)
  end

  def test_validates_enrichment_with_options_format
    params = {
      search: { query: "test", count: 10 },
      enrichments: [
        {
          description: "Categorize size",
          format: "options",
          options: [
            { label: "Small" },
            { label: "Medium" },
            { label: "Large" }
          ]
        }
      ]
    }

    # Should not raise
    Exa::Services::Websets::CreateValidator.validate!(params)
  end

  def test_raises_when_enrichment_missing_description
    params = {
      search: { query: "test", count: 10 },
      enrichments: [{ format: "text" }]
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/description.*required/i, error.message)
  end

  def test_raises_when_enrichment_format_invalid
    params = {
      search: { query: "test", count: 10 },
      enrichments: [
        {
          description: "test",
          format: "invalid_format"
        }
      ]
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/must be one of/i, error.message)
  end

  def test_raises_when_options_format_missing_options
    params = {
      search: { query: "test", count: 10 },
      enrichments: [
        {
          description: "Categorize",
          format: "options"
        }
      ]
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/options.*required/i, error.message)
  end

  def test_validates_scope_with_source_reference
    params = {
      search: {
        query: "test",
        count: 10,
        scope: [
          {
            source: "import",
            id: "import_123"
          }
        ]
      }
    }

    # Should not raise
    Exa::Services::Websets::CreateValidator.validate!(params)
  end

  def test_validates_scope_with_relationship
    params = {
      search: {
        query: "investors",
        count: 10,
        scope: [
          {
            source: "webset",
            id: "ws_companies",
            relationship: {
              definition: "investors of",
              limit: 3
            }
          }
        ]
      }
    }

    # Should not raise
    Exa::Services::Websets::CreateValidator.validate!(params)
  end

  def test_raises_when_relationship_limit_out_of_range
    params = {
      search: {
        query: "test",
        count: 10,
        scope: [
          {
            source: "webset",
            id: "ws_123",
            relationship: {
              definition: "related to",
              limit: 15
            }
          }
        ]
      }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/between 1 and 10/i, error.message)
  end

  def test_validates_exclude_sources
    params = {
      search: { query: "test", count: 10 },
      exclude: [
        {
          source: "webset",
          id: "ws_old"
        }
      ]
    }

    # Should not raise
    Exa::Services::Websets::CreateValidator.validate!(params)
  end

  def test_raises_when_source_reference_missing_id
    params = {
      search: { query: "test", count: 10 },
      exclude: [
        { source: "webset" }
      ]
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/id.*required/i, error.message)
  end

  def test_raises_when_source_type_invalid
    params = {
      search: { query: "test", count: 10 },
      exclude: [
        {
          source: "invalid_source",
          id: "123"
        }
      ]
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/must be one of.*import.*webset/i, error.message)
  end

  def test_validates_external_id
    params = {
      search: { query: "test", count: 10 },
      externalId: "my-custom-id-123"
    }

    # Should not raise
    Exa::Services::Websets::CreateValidator.validate!(params)
  end

  def test_raises_when_external_id_exceeds_max_length
    params = {
      search: { query: "test", count: 10 },
      externalId: "a" * 301
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/300 characters/i, error.message)
  end

  def test_validates_metadata
    params = {
      search: { query: "test", count: 10 },
      metadata: {
        "project" => "Q1-2024",
        "owner" => "team-growth"
      }
    }

    # Should not raise
    Exa::Services::Websets::CreateValidator.validate!(params)
  end

  def test_raises_when_metadata_value_not_string
    params = {
      search: { query: "test", count: 10 },
      metadata: {
        "count" => 123
      }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/must be strings/i, error.message)
  end

  def test_raises_when_metadata_value_exceeds_max_length
    params = {
      search: { query: "test", count: 10 },
      metadata: {
        "long_value" => "a" * 1001
      }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateValidator.validate!(params)
    end

    assert_match(/1000 characters/i, error.message)
  end
end
