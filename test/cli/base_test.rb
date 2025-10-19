# frozen_string_literal: true

require "test_helper"

class Exa::CLI::BaseTest < Minitest::Test
  def test_resolves_api_key_from_flag_first
    api_key = Exa::CLI::Base.resolve_api_key("flag_key")
    assert_equal "flag_key", api_key
  end

  def test_resolves_api_key_from_env_var
    ENV["EXA_API_KEY"] = "env_key"
    api_key = Exa::CLI::Base.resolve_api_key(nil)
    assert_equal "env_key", api_key
  ensure
    ENV.delete("EXA_API_KEY")
  end

  def test_raises_error_when_no_api_key
    ENV.delete("EXA_API_KEY")
    error = assert_raises(Exa::ConfigurationError) do
      Exa::CLI::Base.resolve_api_key(nil)
    end
    assert_includes error.message.downcase, "api key"
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
end
