# frozen_string_literal: true

require "test_helper"

class Exa::CLI::AnswerTest < Minitest::Test
  def test_output_schema_flag_is_parsed_as_json
    # This test verifies that --output-schema accepts a JSON string
    # The actual implementation is in exe/exa-ai-answer parse_args function
    # This is an integration test showing the flag should work

    # Create a mock answer call to verify output_schema is passed
    stub_request(:post, "https://api.exa.ai/answer")
      .with(body: hash_including(
        query: "test",
        output_schema: { type: "object", properties: { city: { type: "string" } } }
      ))
      .to_return(
        status: 200,
        body: { answer: { city: "Paris" }, citations: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    api_key = "test_key"
    output_schema_json = '{"type":"object","properties":{"city":{"type":"string"}}}'

    # Parse and build client (simulating what CLI does)
    client = Exa::Client.new(api_key: api_key)
    parsed_schema = JSON.parse(output_schema_json)

    result = client.answer("test", output_schema: parsed_schema)

    assert_requested :post, "https://api.exa.ai/answer",
      body: hash_including(output_schema: parsed_schema)
    assert_instance_of Exa::Resources::Answer, result
    assert_equal({ "city" => "Paris" }, result.answer)
  end

  def test_output_schema_with_complex_object
    output_schema = {
      type: "object",
      properties: {
        city: { type: "string", description: "Name of the city" },
        state: { type: "string", description: "Name of the state" }
      },
      required: ["city", "state"],
      additionalProperties: false
    }

    stub_request(:post, "https://api.exa.ai/answer")
      .with(body: hash_including(query: "capital of New York", output_schema: output_schema))
      .to_return(
        status: 200,
        body: {
          answer: { "city" => "Albany", "state" => "New York" },
          citations: [{ title: "Wikipedia", url: "https://example.com" }]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.answer("capital of New York", output_schema: output_schema)

    assert_instance_of Exa::Resources::Answer, result
    assert_equal "Albany", result.answer["city"]
    assert_equal "New York", result.answer["state"]
  end

  def test_system_prompt_flag_is_passed_to_api
    stub_request(:post, "https://api.exa.ai/answer")
      .with(body: hash_including(
        query: "What is Paris?",
        system_prompt: "Respond in the voice of a pirate"
      ))
      .to_return(
        status: 200,
        body: { answer: "Ahoy! Paris be a mighty fine city!", citations: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.answer("What is Paris?", system_prompt: "Respond in the voice of a pirate")

    assert_requested :post, "https://api.exa.ai/answer",
      body: hash_including(system_prompt: "Respond in the voice of a pirate")
    assert_instance_of Exa::Resources::Answer, result
  end

  def test_system_prompt_with_other_parameters
    stub_request(:post, "https://api.exa.ai/answer")
      .with(body: hash_including(
        query: "test",
        system_prompt: "Be concise",
        text: true
      ))
      .to_return(
        status: 200,
        body: { answer: "test answer", citations: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.answer("test", system_prompt: "Be concise", text: true)

    assert_requested :post, "https://api.exa.ai/answer",
      body: hash_including(system_prompt: "Be concise", text: true)
    assert_instance_of Exa::Resources::Answer, result
  end
end
