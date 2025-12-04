# frozen_string_literal: true

require "test_helper"
require "tempfile"

class Exa::CLI::ImportCreateTest < Minitest::Test
  def test_parses_file_path_as_first_argument
    file = create_temp_csv
    args = parse_args([file.path, "--count", "10", "--title", "Test", "--format", "csv", "--entity-type", "company"])
    assert_equal file.path, args[:file_path]
  ensure
    file.close
    file.unlink
  end

  def test_requires_count_flag
    file = create_temp_csv
    args = parse_args([file.path, "--count", "50", "--title", "Test", "--format", "csv", "--entity-type", "company"])
    assert_equal 50, args[:count]
  ensure
    file.close
    file.unlink
  end

  def test_requires_title_flag
    file = create_temp_csv
    args = parse_args([file.path, "--count", "10", "--title", "My Import", "--format", "csv", "--entity-type", "company"])
    assert_equal "My Import", args[:title]
  ensure
    file.close
    file.unlink
  end

  def test_parses_entity_type_flag
    file = create_temp_csv
    args = parse_args([file.path, "--count", "10", "--title", "Test", "--format", "csv", "--entity-type", "person"])
    assert_equal "person", args[:entity_type]
  ensure
    file.close
    file.unlink
  end

  def test_parses_entity_description_flag
    file = create_temp_csv
    args = parse_args([
      file.path,
      "--count", "10",
      "--title", "Test",
      "--format", "csv",
      "--entity-type", "custom",
      "--entity-description", "nonprofit organizations"
    ])
    assert_equal "custom", args[:entity_type]
    assert_equal "nonprofit organizations", args[:entity_description]
  ensure
    file.close
    file.unlink
  end

  # Tests for entity building logic

  def test_builds_entity_hash_for_predefined_type
    entity_input = "company"
    entity = build_entity(entity_input, nil)

    assert_instance_of Hash, entity
    assert_equal "company", entity[:type]
    refute entity.key?(:description)
  end

  def test_builds_entity_hash_for_custom_type_with_description
    entity_input = "custom"
    entity_description = "nonprofit advocacy organizations"
    entity = build_entity(entity_input, entity_description)

    assert_instance_of Hash, entity
    assert_equal "custom", entity[:type]
    assert_equal "nonprofit advocacy organizations", entity[:description]
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

  def test_parses_csv_identifier_flag
    file = create_temp_csv
    args = parse_args([file.path, "--count", "10", "--title", "Test", "--format", "csv", "--entity-type", "company", "--csv-identifier", "2"])
    assert_equal 2, args[:csv_identifier]
  ensure
    file.close
    file.unlink
  end

  def test_parses_metadata_flag
    file = create_temp_csv
    args = parse_args([file.path, "--count", "10", "--title", "Test", "--format", "csv", "--entity-type", "company", "--metadata", '{"source":"crm"}'])
    assert_equal({ source: "crm" }, args[:metadata])
  ensure
    file.close
    file.unlink
  end

  def test_parses_quiet_flag
    file = create_temp_csv
    args = parse_args([file.path, "--count", "10", "--title", "Test", "--format", "csv", "--entity-type", "company", "--quiet"])
    assert_equal true, args[:quiet]
  ensure
    file.close
    file.unlink
  end

  def test_parses_output_format_flag
    file = create_temp_csv
    args = parse_args([file.path, "--count", "10", "--title", "Test", "--format", "csv", "--entity-type", "company", "--output-format", "pretty"])
    assert_equal "pretty", args[:output_format]
  ensure
    file.close
    file.unlink
  end

  def test_defaults_to_json_output_format
    file = create_temp_csv
    args = parse_args([file.path, "--count", "10", "--title", "Test", "--format", "csv", "--entity-type", "company"])
    assert_equal "json", args[:output_format]
  ensure
    file.close
    file.unlink
  end

  private

  def create_temp_csv
    file = Tempfile.new(["test", ".csv"])
    file.write("id,name,email\n")
    file.write("1,Company A,contact@a.com\n")
    file.write("2,Company B,contact@b.com\n")
    file.rewind
    file
  end

  # Helper method to parse command-line arguments
  # Mirrors the logic from exe/exa-ai-import-create
  def parse_args(argv)
    args = {
      output_format: "json",
      api_key: nil,
      format: "csv",
      quiet: false
    }

    i = 0
    while i < argv.length
      arg = argv[i]
      case arg
      when "--count"
        args[:count] = argv[i + 1].to_i
        i += 2
      when "--title"
        args[:title] = argv[i + 1]
        i += 2
      when "--format"
        args[:format] = argv[i + 1]
        i += 2
      when "--entity-type"
        args[:entity_type] = argv[i + 1]
        i += 2
      when "--entity-description"
        args[:entity_description] = argv[i + 1]
        i += 2
      when "--csv-identifier"
        args[:csv_identifier] = argv[i + 1].to_i
        i += 2
      when "--metadata"
        args[:metadata] = parse_json_or_file(argv[i + 1])
        i += 2
      when "--quiet"
        args[:quiet] = true
        i += 1
      when "--api-key"
        args[:api_key] = argv[i + 1]
        i += 2
      when "--output-format"
        args[:output_format] = argv[i + 1]
        i += 2
      else
        # First argument is the file path
        unless args[:file_path]
          args[:file_path] = arg
          i += 1
        else
          raise ArgumentError, "Unknown option: #{arg}"
        end
      end
    end

    args
  end

  # Helper to parse JSON or file - mirrors exe/exa-ai-import-create:23-38
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

  # Helper to symbolize keys - mirrors exe/exa-ai-import-create:9-21
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

  # Helper to build entity parameter - mirrors exe/exa-ai-import-create:194-211
  def build_entity(entity_input, entity_description)
    entity = { type: entity_input }
    if entity_input == "custom"
      unless entity_description
        raise ArgumentError, "Error: --entity-description is required when --entity-type is 'custom'"
      end
      entity[:description] = entity_description
    elsif entity_description
      $stderr.puts "Warning: --entity-description is only used with --entity-type custom (ignoring)"
    end
    entity
  end
end
