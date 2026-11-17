# frozen_string_literal: true

require "test_helper"

class Exa::CLI::BaseTest < Minitest::Test
  def test_resolves_api_key_from_flag_first
    api_key = Exa::CLI::Base.resolve_api_key("flag_key")
    assert_equal "flag_key", api_key
  end

  def test_resolves_api_key_from_env_var
    with_api_key("env_key") do
      api_key = Exa::CLI::Base.resolve_api_key(nil)
      assert_equal "env_key", api_key
    end
  end

  def test_raises_error_when_no_api_key
    with_api_key(nil) do
      error = assert_raises(Exa::ConfigurationError) do
        Exa::CLI::Base.resolve_api_key(nil)
      end
      assert_includes error.message.downcase, "api key"
    end
  end

  def test_default_output_format_is_json
    format = Exa::CLI::Base.resolve_output_format(nil)
    assert_equal "json", format
  end

  def test_accepts_json_output_format
    format = Exa::CLI::Base.resolve_output_format("json")
    assert_equal "json", format
  end

  def test_accepts_pretty_output_format
    format = Exa::CLI::Base.resolve_output_format("pretty")
    assert_equal "pretty", format
  end

  def test_accepts_text_output_format
    format = Exa::CLI::Base.resolve_output_format("text")
    assert_equal "text", format
  end

  def test_accepts_toon_output_format
    format = Exa::CLI::Base.resolve_output_format("toon")
    assert_equal "toon", format
  end

  def test_raises_error_on_invalid_output_format
    error = assert_raises(Exa::ConfigurationError) do
      Exa::CLI::Base.resolve_output_format("invalid_format")
    end
    assert_includes error.message.downcase, "format"
  end

  def test_builds_client_with_api_key
    client = Exa::CLI::Base.build_client("test_key")
    assert_instance_of Exa::Client, client
  end

  def test_formats_output_as_json
    data = { key: "value", nested: { inner: 123 } }
    output = Exa::CLI::Base.format_output(data, "json")
    parsed = JSON.parse(output)
    assert_equal "value", parsed["key"]
    assert_equal 123, parsed["nested"]["inner"]
  end

  def test_formats_output_as_pretty_uses_inspect
    data = "test string"
    output = Exa::CLI::Base.format_output(data, "pretty")
    assert_includes output, "test string"
  end

  def test_formats_output_as_text_uses_to_s
    data = "test string"
    output = Exa::CLI::Base.format_output(data, "text")
    assert_equal "test string", output
  end

  def test_encode_as_toon
    data = { key: "value", nested: { inner: 123 } }
    output = Exa::CLI::Base.encode_as_toon(data)

    assert_instance_of String, output
    assert_includes output, "key"
    assert_includes output, "value"
  end

  def test_option_value_returns_the_value
    assert_equal "ai.com", Exa::CLI::Base.option_value("--include-domains", "ai.com")
  end

  def test_option_value_exits_when_value_missing
    stderr, status = capture_exit { Exa::CLI::Base.option_value("--include-domains", nil) }

    assert_equal 1, status
    assert_equal "Error: --include-domains needs a value\n", stderr
  end

  def test_text_value_returns_the_value
    assert_equal "state-of-the-art", Exa::CLI::Base.text_value("--summary-query", "state-of-the-art")
  end

  def test_text_value_exits_when_value_missing
    stderr, status = capture_exit { Exa::CLI::Base.text_value("--summary-query", nil) }

    assert_equal 1, status
    assert_equal "Error: --summary-query needs a value\n", stderr
  end

  def test_text_value_exits_when_next_argument_is_a_flag
    stderr, status = capture_exit { Exa::CLI::Base.text_value("--summary-query", "--text") }

    assert_equal 1, status
    assert_equal "Error: --summary-query needs a value (got the flag --text)\n", stderr
  end

  def test_parse_integer_returns_integer
    assert_equal 25, Exa::CLI::Base.parse_integer("--limit", "25")
  end

  def test_parse_integer_exits_when_value_missing
    stderr, status = capture_exit { Exa::CLI::Base.parse_integer("--limit", nil) }

    assert_equal 1, status
    assert_equal "Error: --limit needs a value\n", stderr
  end

  def test_parse_integer_rejects_values_that_are_not_base_ten_integers
    ["abc", "12abc", "1.5", "0x10"].each do |value|
      stderr, status = capture_exit { Exa::CLI::Base.parse_integer("--limit", value) }

      assert_equal 1, status, value
      assert_equal "Error: --limit must be a number (got #{value.inspect})\n", stderr
    end
  end

  def test_parse_json_or_file_parses_inline_json_with_string_keys
    result = Exa::CLI::Base.parse_json_or_file("--metadata", '{"team":"research"}')

    assert_equal({ "team" => "research" }, result)
  end

  def test_parse_json_or_file_symbolizes_nested_keys_when_asked
    result = Exa::CLI::Base.parse_json_or_file(
      "--criteria", '[{"description":"Series A funding"}]', symbolize_names: true
    )

    assert_equal [{ description: "Series A funding" }], result
  end

  def test_parse_json_or_file_reads_file_after_at_sign
    Tempfile.create(["schema", ".json"]) do |file|
      file.write('{"type":"object"}')
      file.flush

      result = Exa::CLI::Base.parse_json_or_file("--output-schema", "@#{file.path}")

      assert_equal({ "type" => "object" }, result)
    end
  end

  def test_parse_json_or_file_exits_on_invalid_json
    stderr, status = capture_exit { Exa::CLI::Base.parse_json_or_file("--metadata", "{not json") }

    assert_equal 1, status
    assert_match(/\AError: --metadata is not valid JSON: .+\n\z/, stderr)
  end

  def test_parse_json_or_file_exits_when_file_missing
    stderr, status = capture_exit do
      Exa::CLI::Base.parse_json_or_file("--metadata", "@/nonexistent/metadata.json")
    end

    assert_equal 1, status
    assert_match(%r{\AError: --metadata file could not be read: .*/nonexistent/metadata\.json\n\z}, stderr)
  end

  def test_parse_json_or_file_exits_when_value_missing
    stderr, status = capture_exit { Exa::CLI::Base.parse_json_or_file("--metadata", nil) }

    assert_equal 1, status
    assert_equal "Error: --metadata needs a value\n", stderr
  end

  private

  # Run the block, which must exit, and return its stderr and exit status.
  def capture_exit
    status = nil
    _stdout, stderr = capture_io do
      error = assert_raises(SystemExit) { yield }
      status = error.status
    end
    [stderr, status]
  end
end
