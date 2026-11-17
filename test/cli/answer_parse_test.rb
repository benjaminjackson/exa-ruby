# frozen_string_literal: true

require "test_helper"

# Runs exe/exa-ai-answer in-process and checks how its flags reach the
# request body.
class AnswerParseTest < Minitest::Test
  ANSWER_URL = "https://api.exa.ai/answer"
  QUERY = "What is the capital of France?"

  def test_sends_output_schema_parsed_as_json
    body, = post_answer(QUERY, "--output-schema", '{"type":"object","properties":{"city":{"type":"string"}}}')

    assert_equal({ "type" => "object", "properties" => { "city" => { "type" => "string" } } }, body["outputSchema"])
    assert_equal QUERY, body["query"]
  end

  def test_sends_system_prompt
    body, = post_answer(QUERY, "--system-prompt", "Respond in the voice of a pirate")

    assert_equal "Respond in the voice of a pirate", body["systemPrompt"]
    assert_equal QUERY, body["query"]
  end

  def test_omits_output_schema_and_system_prompt_when_not_given
    body, = post_answer(QUERY)

    refute body.key?("outputSchema")
    refute body.key?("systemPrompt")
    assert_equal QUERY, body["query"]
  end

  def test_combines_text_system_prompt_output_schema_and_output_format
    body, stdout = post_answer(
      QUERY, "--text", "--system-prompt", "Be concise", "--output-schema", "{}", "--output-format", "pretty"
    )

    assert_equal true, body["text"]
    assert_equal "Be concise", body["systemPrompt"]
    assert_equal({}, body["outputSchema"])
    assert_requested(:post, ANSWER_URL, headers: { "x-api-key" => "test_key" })
    assert_raises(JSON::ParserError) { JSON.parse(stdout) }
    assert_includes stdout, "Paris is the capital of France."
  end

  def test_rejects_invalid_user_location_json_with_one_line
    stub_request(:post, ANSWER_URL)

    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-answer", QUERY, "--user-location", "{bad", "--api-key", "test_key"
    )

    assert_equal 1, exit_status
    assert_equal 1, stderr.lines.count
    assert_match(/\AError: --user-location is not valid JSON/, stderr)
    assert_not_requested :post, ANSWER_URL
  end

  private

  # Runs exa-ai-answer in-process with the given arguments. Returns the
  # parsed body of the request it sends and stdout.
  def post_answer(*argv)
    posted_body = nil
    stub_request(:post, ANSWER_URL)
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(
        status: 200,
        body: { answer: "Paris is the capital of France.", citations: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stdout, stderr, exit_status = run_exe_in_process("exa-ai-answer", *argv, "--api-key", "test_key")

    assert_nil exit_status, "command failed: #{stderr}"
    [posted_body, stdout]
  end
end
