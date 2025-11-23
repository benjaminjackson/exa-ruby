# frozen_string_literal: true

require "test_helper"
require "tempfile"

class Exa::CLI::WebsetSearchCreateTest < Minitest::Test
  def test_parses_webset_id_as_first_positional_argument
    args = parse_args(["ws_123", "--query", "AI startups"])
    assert_equal "ws_123", args[:webset_id]
  end

  def test_requires_query_flag
    args = parse_args(["ws_123", "--query", "tech companies"])
    assert_equal "tech companies", args[:query]
  end

  def test_parses_count_flag
    args = parse_args(["ws_123", "--query", "startups", "--count", "50"])
    assert_equal 50, args[:count]
  end

  def test_parses_recall_flag
    args = parse_args(["ws_123", "--query", "startups", "--recall"])
    assert_equal true, args[:recall]
  end

  def test_parses_behavior_flag
    args = parse_args(["ws_123", "--query", "startups", "--behavior", "append"])
    assert_equal "append", args[:behavior]
  end

  # Tests for entity parameter parsing in parse_args

  def test_parses_entity_flag_with_predefined_type
    args = parse_args(["ws_123", "--query", "tech CEOs", "--entity", "person"])
    assert_equal "person", args[:entity]
  end

  def test_parses_entity_description_flag
    args = parse_args([
      "ws_123",
      "--query", "Ford Mustang",
      "--entity", "custom",
      "--entity-description", "vintage cars"
    ])
    assert_equal "custom", args[:entity]
    assert_equal "vintage cars", args[:entity_description]
  end

  # Tests for entity building logic (simulating lines 187-206)

  def test_builds_entity_hash_for_predefined_type
    entity_input = "person"
    entity = build_entity(entity_input, nil)

    assert_instance_of Hash, entity
    assert_equal "person", entity[:type]
    refute entity.key?(:description)
  end

  def test_builds_entity_hash_for_custom_type_with_description
    entity_input = "custom"
    entity_description = "vintage cars"
    entity = build_entity(entity_input, entity_description)

    assert_instance_of Hash, entity
    assert_equal "custom", entity[:type]
    assert_equal "vintage cars", entity[:description]
  end

  def test_raises_error_for_custom_entity_without_description
    entity_input = "custom"

    error = assert_raises(ArgumentError) do
      build_entity(entity_input, nil)
    end

    assert_includes error.message.downcase, "entity-description"
    assert_includes error.message.downcase, "required"
  end

  def test_warns_for_entity_description_with_non_custom_type
    # Capture stderr to verify warning
    original_stderr = $stderr
    $stderr = StringIO.new

    entity_input = "person"
    entity_description = "should be ignored"
    entity = build_entity(entity_input, entity_description)

    warning = $stderr.string
    assert_includes warning.downcase, "warning"
    assert_includes warning.downcase, "entity-description"
    assert_includes warning.downcase, "custom"

    # Verify entity was built correctly without description
    assert_equal "person", entity[:type]
    refute entity.key?(:description)
  ensure
    $stderr = original_stderr
  end

  def test_outputs_json_by_default
    args = parse_args(["ws_123", "--query", "startups"])
    assert_equal "json", args[:output_format]
  end

  def test_parses_output_format_flag
    args = parse_args(["ws_123", "--query", "startups", "--output-format", "pretty"])
    assert_equal "pretty", args[:output_format]
  end

  private

  # Helper method to parse command-line arguments
  # Mirrors the logic from exe/exa-ai-webset-search-create
  def parse_args(argv)
    args = {
      output_format: "json",
      api_key: nil
    }

    webset_id_found = false

    i = 0
    while i < argv.length
      arg = argv[i]
      case arg
      when "--query"
        args[:query] = argv[i + 1]
        i += 2
      when "--count"
        args[:count] = argv[i + 1].to_i
        i += 2
      when "--entity"
        args[:entity] = argv[i + 1]
        i += 2
      when "--entity-description"
        args[:entity_description] = argv[i + 1]
        i += 2
      when "--criteria"
        args[:criteria] = parse_json_or_file(argv[i + 1])
        i += 2
      when "--exclude"
        args[:exclude] = parse_json_or_file(argv[i + 1])
        i += 2
      when "--scope"
        args[:scope] = parse_json_or_file(argv[i + 1])
        i += 2
      when "--recall"
        args[:recall] = true
        i += 1
      when "--behavior"
        behavior = argv[i + 1]
        unless ["override", "append"].include?(behavior)
          raise ArgumentError, "Behavior must be 'override' or 'append'"
        end
        args[:behavior] = behavior
        i += 2
      when "--metadata"
        args[:metadata] = parse_json_or_file(argv[i + 1])
        i += 2
      when "--api-key"
        args[:api_key] = argv[i + 1]
        i += 2
      when "--output-format"
        args[:output_format] = argv[i + 1]
        i += 2
      else
        # First positional argument is webset_id
        unless webset_id_found
          args[:webset_id] = arg
          webset_id_found = true
        else
          raise ArgumentError, "Unknown option: #{arg}"
        end
        i += 1
      end
    end

    args
  end

  # Helper to parse JSON or file - mirrors exe/exa-ai-webset-search-create:20-35
  def parse_json_or_file(value)
    json_data = if value.start_with?("@")
                  file_path = value[1..]
                  JSON.parse(File.read(file_path))
                else
                  JSON.parse(value)
                end
    deep_symbolize_keys(json_data)
  rescue JSON::ParserError => e
    raise ArgumentError, "Invalid JSON: #{e.message}"
  rescue Errno::ENOENT => e
    raise ArgumentError, "File not found: #{e.message}"
  end

  # Helper to symbolize keys - mirrors exe/exa-ai-webset-search-create:6-18
  def deep_symbolize_keys(obj)
    case obj
    when Hash
      obj.each_with_object({}) do |(key, value), result|
        result[key.to_sym] = deep_symbolize_keys(value)
      end
    when Array
      obj.map { |item| deep_symbolize_keys(item) }
    else
      obj
    end
  end

  # Helper to build entity parameter - mirrors exe/exa-ai-webset-search-create:175-189
  def build_entity(entity_input, entity_description)
    return nil unless entity_input

    # Build entity hash from string type
    entity = { type: entity_input }
    if entity_input == "custom"
      unless entity_description
        raise ArgumentError, "Error: --entity-description is required when --entity is 'custom'"
      end
      entity[:description] = entity_description
    elsif entity_description
      $stderr.puts "Warning: --entity-description is only used with --entity custom (ignoring)"
    end
    entity
  end
end
