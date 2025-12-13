# frozen_string_literal: true

require "test_helper"

class Exa::CLI::EnrichmentCreateTest < Minitest::Test
  # Test that CLI uses the correct format constant
  def test_cli_script_uses_correct_format_constant
    cli_content = File.read(File.expand_path("../../exe/exa-ai-enrichment-create", __dir__))

    # The CLI should use the constant from Exa::Constants::Websets
    assert_includes cli_content, "Exa::Constants::Websets::ENRICHMENT_FORMATS",
      "CLI should use Exa::Constants::Websets::ENRICHMENT_FORMATS instead of hardcoded list"
  end

  def test_format_constant_includes_all_valid_formats
    # Verify the constant has all 7 valid formats per API spec
    expected_formats = %w[text date number options email phone url]
    assert_equal expected_formats.sort, Exa::Constants::Websets::ENRICHMENT_FORMATS.sort
  end

  # Test argument parsing
  def test_accepts_text_format
    args = parse_args(["ws_123", "--description", "Company size", "--format", "text"])
    assert_equal "text", args[:format]
  end

  def test_accepts_date_format
    args = parse_args(["ws_123", "--description", "Founded date", "--format", "date"])
    assert_equal "date", args[:format]
  end

  def test_accepts_number_format
    args = parse_args(["ws_123", "--description", "Employee count", "--format", "number"])
    assert_equal "number", args[:format]
  end

  def test_accepts_options_format
    args = parse_args(["ws_123", "--description", "Industry", "--format", "options"])
    assert_equal "options", args[:format]
  end

  def test_accepts_url_format
    args = parse_args(["ws_123", "--description", "Website URL", "--format", "url"])
    assert_equal "url", args[:format]
  end

  def test_accepts_email_format
    args = parse_args(["ws_123", "--description", "Contact email", "--format", "email"])
    assert_equal "email", args[:format]
  end

  def test_accepts_phone_format
    args = parse_args(["ws_123", "--description", "Phone number", "--format", "phone"])
    assert_equal "phone", args[:format]
  end

  # Test format validation
  def test_valid_format_passes_validation
    # Should not raise for valid formats
    %w[text date number options email phone url].each do |format|
      assert validate_format(format), "Format '#{format}' should be valid"
    end
  end

  def test_invalid_format_fails_validation
    # Capture stderr to prevent test output pollution
    original_stderr = $stderr
    $stderr = StringIO.new

    # Should exit with status 1 for invalid format
    assert_raises(SystemExit) do
      validate_format("invalid_format")
    end

    assert_raises(SystemExit) do
      validate_format("pdf")
    end
  ensure
    $stderr = original_stderr
  end

  private

  # Mirror the VALID_FORMATS constant that should be used
  # This should match Exa::Constants::Websets::ENRICHMENT_FORMATS
  VALID_FORMATS = Exa::Constants::Websets::ENRICHMENT_FORMATS

  # Helper method to parse command-line arguments
  # Mirrors the logic from exe/exa-ai-enrichment-create
  def parse_args(argv)
    args = {
      output_format: "json",
      api_key: nil,
      wait: false
    }

    # First, check for positional argument (webset_id)
    if argv.empty? || argv[0].start_with?("--")
      return args
    end

    args[:webset_id] = argv[0]
    i = 1

    while i < argv.length
      arg = argv[i]
      case arg
      when "--description"
        args[:description] = argv[i + 1]
        i += 2
      when "--format"
        args[:format] = argv[i + 1]
        i += 2
      when "--options"
        args[:options] = parse_json_or_file(argv[i + 1])
        i += 2
      when "--metadata"
        args[:metadata] = parse_json_or_file(argv[i + 1])
        i += 2
      when "--wait"
        args[:wait] = true
        i += 1
      when "--api-key"
        args[:api_key] = argv[i + 1]
        i += 2
      when "--output-format"
        args[:output_format] = argv[i + 1]
        i += 2
      else
        raise ArgumentError, "Unknown option: #{arg}"
      end
    end

    args
  end

  # Helper to validate format - mirrors exe/exa-ai-enrichment-create:139-143
  def validate_format(format)
    if VALID_FORMATS.include?(format)
      true
    else
      $stderr.puts "Error: format must be one of: #{VALID_FORMATS.join(', ')}"
      exit 1
    end
  end

  # Helper to parse JSON or file - mirrors exe/exa-ai-enrichment-create:23-37
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

  # Helper to symbolize keys - mirrors exe/exa-ai-enrichment-create:9-21
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
end
