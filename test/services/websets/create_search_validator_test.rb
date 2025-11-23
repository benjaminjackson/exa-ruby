# frozen_string_literal: true

require "test_helper"

class CreateSearchValidatorTest < Minitest::Test
  def test_validates_valid_minimal_params
    params = {
      query: "AI startups",
      count: 10
    }

    # Should not raise
    Exa::Services::Websets::CreateSearchValidator.validate!(params)
  end

  def test_validates_custom_entity_with_description
    params = {
      query: "sustainability initiatives",
      count: 10,
      entity: {
        type: "custom",
        description: "environmental conservation projects"
      }
    }

    # Should not raise
    Exa::Services::Websets::CreateSearchValidator.validate!(params)
  end

  def test_raises_when_custom_entity_missing_description
    params = {
      query: "test",
      count: 10,
      entity: { type: "custom" }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/description.*required/i, error.message)
  end

  def test_raises_when_entity_description_too_short
    params = {
      query: "test",
      count: 10,
      entity: {
        type: "custom",
        description: "a"
      }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/at least 2 characters/i, error.message)
  end

  def test_raises_when_entity_description_too_long
    params = {
      query: "test",
      count: 10,
      entity: {
        type: "custom",
        description: "a" * 201
      }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/cannot exceed 200 characters/i, error.message)
  end

  def test_validates_standard_entity_types
    %w[company person article research_paper].each do |type|
      params = {
        query: "test",
        count: 10,
        entity: { type: type }
      }

      # Should not raise
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end
  end

  def test_raises_when_entity_type_invalid
    params = {
      query: "test",
      count: 10,
      entity: { type: "invalid_type" }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/entity\[:type\] must be one of/i, error.message)
  end

  def test_raises_when_entity_type_missing
    params = {
      query: "test",
      count: 10,
      entity: { description: "test" }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/entity\[:type\] is required/i, error.message)
  end

  def test_validates_criteria_array
    params = {
      query: "test",
      count: 10,
      criteria: [
        { description: "criterion 1" },
        { description: "criterion 2" }
      ]
    }

    # Should not raise
    Exa::Services::Websets::CreateSearchValidator.validate!(params)
  end

  def test_raises_when_criteria_empty
    params = {
      query: "test",
      count: 10,
      criteria: []
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/at least 1 item/i, error.message)
  end

  def test_raises_when_criteria_exceeds_max
    params = {
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

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/cannot have more than 5 items/i, error.message)
  end

  def test_validates_behavior_override
    params = {
      query: "test",
      count: 10,
      behavior: "override"
    }

    # Should not raise
    Exa::Services::Websets::CreateSearchValidator.validate!(params)
  end

  def test_validates_behavior_append
    params = {
      query: "test",
      count: 10,
      behavior: "append"
    }

    # Should not raise
    Exa::Services::Websets::CreateSearchValidator.validate!(params)
  end

  def test_raises_when_behavior_invalid
    params = {
      query: "test",
      count: 10,
      behavior: "invalid"
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/behavior must be one of/i, error.message)
  end

  def test_validates_metadata
    params = {
      query: "test",
      count: 10,
      metadata: {
        "key1" => "value1",
        "key2" => "value2"
      }
    }

    # Should not raise
    Exa::Services::Websets::CreateSearchValidator.validate!(params)
  end

  def test_raises_when_metadata_value_not_string
    params = {
      query: "test",
      count: 10,
      metadata: {
        "key" => 123
      }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/metadata values must be Strings/i, error.message)
  end

  def test_raises_when_metadata_value_too_long
    params = {
      query: "test",
      count: 10,
      metadata: {
        "key" => "a" * 1001
      }
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/cannot exceed 1000 characters/i, error.message)
  end

  def test_raises_when_query_empty
    params = {
      query: "   ",
      count: 10
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/query cannot be empty/i, error.message)
  end

  def test_raises_when_query_too_long
    params = {
      query: "a" * 5001,
      count: 10
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/query cannot exceed 5000 characters/i, error.message)
  end

  def test_raises_when_count_not_positive
    params = {
      query: "test",
      count: 0
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/count must be a positive Integer/i, error.message)
  end

  def test_validates_exclude_array
    params = {
      query: "test",
      count: 10,
      exclude: [
        { source: "webset", id: "webset_123" }
      ]
    }

    # Should not raise
    Exa::Services::Websets::CreateSearchValidator.validate!(params)
  end

  def test_validates_scope_array
    params = {
      query: "test",
      count: 10,
      scope: [
        { source: "webset", id: "webset_123" }
      ]
    }

    # Should not raise
    Exa::Services::Websets::CreateSearchValidator.validate!(params)
  end

  def test_validates_scope_with_relationship
    params = {
      query: "test",
      count: 10,
      scope: [
        {
          source: "webset",
          id: "webset_123",
          relationship: {
            definition: "companies that compete with",
            limit: 5
          }
        }
      ]
    }

    # Should not raise
    Exa::Services::Websets::CreateSearchValidator.validate!(params)
  end

  def test_raises_when_scope_relationship_limit_out_of_range
    params = {
      query: "test",
      count: 10,
      scope: [
        {
          source: "webset",
          id: "webset_123",
          relationship: {
            definition: "companies that compete with",
            limit: 11
          }
        }
      ]
    }

    error = assert_raises(ArgumentError) do
      Exa::Services::Websets::CreateSearchValidator.validate!(params)
    end

    assert_match(/relationship\]\[:limit\] must be an Integer between 1 and 10/i, error.message)
  end
end
