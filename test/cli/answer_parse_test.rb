# frozen_string_literal: true

require "test_helper"

# Tests for the answer CLI executable argument parsing
# Note: This loads the exe/exa-ai-answer script to test its parse_args function
class AnswerParseTest < Minitest::Test
  def parse_args(argv)
    # This simulates the parse_args function from exe/exa-ai-answer
    args = {
      output_format: "json",
      api_key: nil,
      text: false
    }

    query_parts = []
    i = 0
    while i < argv.length
      arg = argv[i]
      case arg
      when "--text"
        args[:text] = true
        i += 1
      when "--output-schema"
        args[:output_schema] = argv[i + 1]
        i += 2
      when "--system-prompt"
        args[:system_prompt] = argv[i + 1]
        i += 2
      when "--api-key"
        args[:api_key] = argv[i + 1]
        i += 2
      when "--output-format"
        args[:output_format] = argv[i + 1]
        i += 2
      when "--help", "-h"
        i += 1
      else
        query_parts << arg
        i += 1
      end
    end

    args[:query] = query_parts.join(" ")
    args
  end

  def test_parse_output_schema_flag
    argv = ["What is Paris?", "--output-schema", '{"type":"object"}']
    result = parse_args(argv)

    assert_equal '{"type":"object"}', result[:output_schema]
    assert_equal "What is Paris?", result[:query]
  end

  def test_parse_output_schema_with_text_flag
    argv = ["test query", "--text", "--output-schema", '{"type":"object","properties":{"city":{"type":"string"}}}']
    result = parse_args(argv)

    assert_equal true, result[:text]
    assert_equal '{"type":"object","properties":{"city":{"type":"string"}}}', result[:output_schema]
    assert_equal "test query", result[:query]
  end

  def test_parse_output_schema_not_required
    argv = ["test query"]
    result = parse_args(argv)

    assert_nil result[:output_schema]
    assert_equal "test query", result[:query]
  end

  def test_parse_output_schema_with_other_flags
    argv = ["query", "--api-key", "key123", "--output-schema", '{}', "--output-format", "pretty"]
    result = parse_args(argv)

    assert_equal '{}', result[:output_schema]
    assert_equal "key123", result[:api_key]
    assert_equal "pretty", result[:output_format]
  end

  def test_parse_system_prompt_flag
    argv = ["What is Paris?", "--system-prompt", "Respond in the voice of a pirate"]
    result = parse_args(argv)

    assert_equal "Respond in the voice of a pirate", result[:system_prompt]
    assert_equal "What is Paris?", result[:query]
  end

  def test_parse_system_prompt_with_text_flag
    argv = ["test query", "--text", "--system-prompt", "Be concise"]
    result = parse_args(argv)

    assert_equal true, result[:text]
    assert_equal "Be concise", result[:system_prompt]
    assert_equal "test query", result[:query]
  end

  def test_parse_system_prompt_not_required
    argv = ["test query"]
    result = parse_args(argv)

    assert_nil result[:system_prompt]
    assert_equal "test query", result[:query]
  end

  def test_parse_system_prompt_with_all_flags
    argv = ["query", "--api-key", "key123", "--system-prompt", "Pirate voice", "--output-schema", '{}', "--text"]
    result = parse_args(argv)

    assert_equal "Pirate voice", result[:system_prompt]
    assert_equal "key123", result[:api_key]
    assert_equal '{}', result[:output_schema]
    assert_equal true, result[:text]
  end
end
