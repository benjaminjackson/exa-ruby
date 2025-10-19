# frozen_string_literal: true

require "test_helper"

class Exa::CLI::IntegrationTest < Minitest::Test
  def setup
    @original_api_key = ENV["EXA_API_KEY"]
    ENV["EXA_API_KEY"] = "test_api_key"
  end

  def teardown
    if @original_api_key
      ENV["EXA_API_KEY"] = @original_api_key
    else
      ENV.delete("EXA_API_KEY")
    end
  end

  def test_search_client_initialization
    client = Exa::Client.new(api_key: "test_api_key")
    assert_instance_of Exa::Client, client
  end

  def test_research_start_client_initialization
    client = Exa::Client.new(api_key: "test_api_key")
    assert_instance_of Exa::Client, client
  end

  def test_context_client_initialization
    client = Exa::Client.new(api_key: "test_api_key")
    assert_instance_of Exa::Client, client
  end

  def test_get_contents_client_initialization
    client = Exa::Client.new(api_key: "test_api_key")
    assert_instance_of Exa::Client, client
  end

  def test_research_get_client_initialization
    client = Exa::Client.new(api_key: "test_api_key")
    assert_instance_of Exa::Client, client
  end

  def test_research_list_client_initialization
    client = Exa::Client.new(api_key: "test_api_key")
    assert_instance_of Exa::Client, client
  end

  def test_api_key_from_env_variable
    assert_equal "test_api_key", ENV["EXA_API_KEY"]

    api_key = Exa::CLI::Base.resolve_api_key(nil)
    assert_equal "test_api_key", api_key
  end

  def test_api_key_flag_overrides_env_variable
    api_key = Exa::CLI::Base.resolve_api_key("flag_api_key")
    assert_equal "flag_api_key", api_key
  end

  def test_missing_api_key_raises_error
    ENV.delete("EXA_API_KEY")

    error = assert_raises(Exa::ConfigurationError) do
      Exa::CLI::Base.resolve_api_key(nil)
    end

    assert_includes error.message.downcase, "api key"
  end

  def test_output_format_defaults_to_json
    format = Exa::CLI::Base.resolve_output_format(nil)
    assert_equal "json", format
  end

  def test_output_format_respects_pretty_flag
    format = Exa::CLI::Base.resolve_output_format("pretty")
    assert_equal "pretty", format
  end

  def test_output_format_invalid_raises_error
    error = assert_raises(Exa::ConfigurationError) do
      Exa::CLI::Base.resolve_output_format("invalid")
    end

    assert_includes error.message.downcase, "format"
  end

  def test_client_initialization_with_api_key
    client = Exa::CLI::Base.build_client("test_key")
    assert_instance_of Exa::Client, client
  end

  def test_formatting_json_output
    data = { results: [{ title: "Test" }] }
    output = Exa::CLI::Base.format_output(data, "json")

    assert_includes output, "results"
    assert_includes output, "Test"
  end

  def test_formatting_pretty_output
    data = { results: [{ title: "Test" }] }
    output = Exa::CLI::Base.format_output(data, "pretty")

    assert_includes output, "results"
  end

  def test_formatting_text_output
    data = "Simple text result"
    output = Exa::CLI::Base.format_output(data, "text")

    assert_equal "Simple text result", output
  end
end
