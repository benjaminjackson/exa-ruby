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
        outputSchema: { type: "object", properties: { city: { type: "string" } } }
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
      body: hash_including(outputSchema: parsed_schema)
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
      .with(body: hash_including(query: "capital of New York", outputSchema: output_schema))
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
        systemPrompt: "Respond in the voice of a pirate"
      ))
      .to_return(
        status: 200,
        body: { answer: "Ahoy! Paris be a mighty fine city!", citations: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = Exa::Client.new(api_key: "test_key")
    result = client.answer("What is Paris?", system_prompt: "Respond in the voice of a pirate")

    assert_requested :post, "https://api.exa.ai/answer",
      body: hash_including(systemPrompt: "Respond in the voice of a pirate")
    assert_instance_of Exa::Resources::Answer, result
  end

  def test_system_prompt_with_other_parameters
    stub_request(:post, "https://api.exa.ai/answer")
      .with(body: hash_including(
        query: "test",
        systemPrompt: "Be concise",
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
      body: hash_including(systemPrompt: "Be concise", text: true)
    assert_instance_of Exa::Resources::Answer, result
  end

  def test_help_lists_model_user_location_and_user_identifier
    output = `bundle exec exe/exa-ai-answer --help`

    %w[--model --user-location --user-identifier].each do |flag|
      assert_includes output, flag
    end
  end

  def test_exe_sends_model_user_location_and_user_identifier
    posted_body = nil
    stub_request(:post, "https://api.exa.ai/answer")
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(status: 200, body: { answer: "About $350 billion", citations: [] }.to_json, headers: { "Content-Type" => "application/json" })

    run_exe_in_process(
      "exa-ai-answer", "What is the latest valuation of SpaceX?", "--api-key", "test_key",
      "--model", "exa-pro", "--user-location", "US", "--user-identifier", "user_42"
    )

    assert_equal "exa-pro", posted_body["model"]
    assert_equal "US", posted_body["userLocation"]
    assert_equal "user_42", posted_body["userIdentifier"]
  end

  def test_exe_stream_sends_model_user_location_and_user_identifier
    posted_body = nil
    stub_request(:post, "https://api.exa.ai/answer")
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(status: 200, body: "data: [DONE]\n\n", headers: { "Content-Type" => "text/event-stream" })

    run_exe_in_process(
      "exa-ai-answer", "What is the latest valuation of SpaceX?", "--api-key", "test_key", "--stream",
      "--model", "exa-fast", "--user-location", '{"country":"US","latitude":37.77,"longitude":-122.42}',
      "--user-identifier", "user_42"
    )

    assert_equal true, posted_body["stream"]
    assert_equal "exa-fast", posted_body["model"]
    assert_equal({ "country" => "US", "latitude" => 37.77, "longitude" => -122.42 }, posted_body["userLocation"])
    assert_equal "user_42", posted_body["userIdentifier"]
  end

  def test_exe_rejects_unknown_model
    stub_request(:post, "https://api.exa.ai/answer")
      .to_return(status: 200, body: { answer: "unused", citations: [] }.to_json, headers: { "Content-Type" => "application/json" })

    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-answer", "What is the latest valuation of SpaceX?", "--api-key", "test_key", "--model", "gpt-4"
    )

    assert_equal 1, exit_status
    assert_includes stderr, "exa-research"
    assert_not_requested :post, "https://api.exa.ai/answer"
  end

  def test_exe_skips_user_location_without_value
    posted_body = nil
    stub_request(:post, "https://api.exa.ai/answer")
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(status: 200, body: { answer: "About $350 billion", citations: [] }.to_json, headers: { "Content-Type" => "application/json" })

    _stdout, _stderr, exit_status = run_exe_in_process(
      "exa-ai-answer", "What is the latest valuation of SpaceX?", "--api-key", "test_key", "--user-location"
    )

    assert_nil exit_status
    refute posted_body.key?("userLocation")
  end
end
