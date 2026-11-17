# frozen_string_literal: true

require "test_helper"

class ParameterConverterTest < Minitest::Test
  # Calls ParameterConverter.convert, which search and find_similar use.
  def convert(params)
    Exa::Services::ParameterConverter.convert(params)
  end

  # Calls ParameterConverter.convert_contents, which get_contents uses.
  def convert_contents(params)
    Exa::Services::ParameterConverter.convert_contents(params)
  end

  def test_convert_contents_folds_flat_key_at_top_level
    result = convert_contents(urls: ["https://example.com"], text_max_characters: 500)

    assert_equal({ urls: ["https://example.com"], text: { maxCharacters: 500 } }, result)
  end

  def test_convert_contents_folds_flat_key_given_before_parent_true
    assert_equal({ text: { maxCharacters: 500 } }, convert_contents(text_max_characters: 500, text: true))
  end

  def test_convert_contents_folds_flat_key_given_after_parent_true
    assert_equal({ text: { maxCharacters: 500 } }, convert_contents(text: true, text_max_characters: 500))
  end

  def test_convert_contents_merges_flat_key_into_parent_hash
    result = convert_contents(summary: { query: "main points" }, summary_schema: { type: "object" })

    assert_equal({ summary: { query: "main points", schema: { type: "object" } } }, result)
  end

  def test_convert_contents_keeps_schema_keys_as_given
    schema = { "type" => "object", "properties" => { "job_title" => { "type" => "string" } } }

    result = convert_contents(summary_schema: schema)

    assert_equal({ summary: { schema: schema } }, result)
  end

  def test_convert_folds_flat_key_given_before_parent_true
    assert_equal({ contents: { text: { maxCharacters: 500 } } }, convert(text_max_characters: 500, text: true))
  end

  def test_convert_merges_nested_contents_hash_with_flat_parent_true
    result = convert(contents: { text: { max_characters: 5 } }, text: true)

    assert_equal({ contents: { text: { maxCharacters: 5 } } }, result)
  end

  def test_convert_merges_string_contents_key_into_one_contents_key
    result = convert("contents" => { "text" => true }, summary: true)

    assert_equal({ contents: { "text" => true, summary: true } }, result)
    assert_equal({ "contents" => { "text" => true, "summary" => true } }, JSON.parse(JSON.generate(result)))
  end

  def test_convert_lets_flat_key_win_over_contents_on_conflict
    result = convert(contents: { text: { max_characters: 5 } }, text_max_characters: 500)

    assert_equal({ contents: { text: { maxCharacters: 500 } } }, result)
  end

  def test_convert_keeps_schema_keys_under_summary_schema_as_given
    schema = { "type" => "object", "properties" => { "job_title" => { "type" => "string" } } }

    result = convert(summary_schema: schema)

    assert_equal({ contents: { summary: { schema: schema } } }, result)
  end
end
