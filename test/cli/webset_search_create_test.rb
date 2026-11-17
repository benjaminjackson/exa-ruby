# frozen_string_literal: true

require "test_helper"

class Exa::CLI::WebsetSearchCreateTest < Minitest::Test
  WEBSET_ID = "ws_ai_infrastructure"
  SEARCHES_URL = "https://api.exa.ai/websets/v0/websets/#{WEBSET_ID}/searches"

  def test_sends_query_to_webset_given_as_first_argument
    body, = post_search("--query", "AI infrastructure startups with Series A funding")

    assert_equal "AI infrastructure startups with Series A funding", body["query"]
  end

  def test_sends_count_in_request_body
    body, = post_search("--query", "venture-backed SaaS companies", "--count", "50")

    assert_equal 50, body["count"]
  end

  def test_sends_recall_in_request_body
    body, = post_search("--query", "venture-backed SaaS companies", "--recall")

    assert_equal true, body["recall"]
  end

  def test_sends_behavior_in_request_body
    body, = post_search("--query", "venture-backed SaaS companies", "--behavior", "append")

    assert_equal "append", body["behavior"]
  end

  def test_sends_predefined_entity_type_without_description
    body, = post_search("--query", "CTOs of robotics companies", "--entity", "person")

    assert_equal({ "type" => "person" }, body["entity"])
  end

  def test_sends_custom_entity_with_description
    body, = post_search(
      "--query", "Ford Mustang listings", "--entity", "custom", "--entity-description", "vintage cars for sale"
    )

    assert_equal({ "type" => "custom", "description" => "vintage cars for sale" }, body["entity"])
  end

  def test_custom_entity_without_description_exits_before_any_request
    stub_request(:post, SEARCHES_URL)

    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-webset-search-create", WEBSET_ID,
      "--query", "Ford Mustang listings", "--entity", "custom", "--api-key", "test_key"
    )

    assert_equal 1, exit_status
    assert_includes stderr, "--entity-description is required"
    assert_not_requested :post, SEARCHES_URL
  end

  def test_warns_and_drops_entity_description_for_non_custom_type
    body, stderr = post_search(
      "--query", "CTOs of robotics companies", "--entity", "person", "--entity-description", "robotics executives"
    )

    assert_includes stderr, "Warning: --entity-description is only used with --entity custom"
    assert_equal({ "type" => "person" }, body["entity"])
  end

  def test_prints_json_by_default
    _body, _stderr, stdout = post_search("--query", "venture-backed SaaS companies")

    assert_equal "ws_search_saas", JSON.parse(stdout)["id"]
  end

  def test_prints_pretty_output_when_asked
    _body, _stderr, stdout = post_search("--query", "venture-backed SaaS companies", "--output-format", "pretty")

    assert_raises(JSON::ParserError) { JSON.parse(stdout) }
    assert_includes stdout, "ws_search_saas"
  end

  private

  # Runs exa-ai-webset-search-create in-process with the given flags.
  # Returns the parsed body of the request it sends, stderr and stdout.
  def post_search(*flags)
    posted_body = nil
    stub_request(:post, SEARCHES_URL)
      .with { |request| posted_body = JSON.parse(request.body) }
      .to_return(
        status: 200,
        body: { id: "ws_search_saas", object: "webset_search", status: "created", websetId: WEBSET_ID }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-webset-search-create", WEBSET_ID, *flags, "--api-key", "test_key"
    )

    assert_nil exit_status, "command failed: #{stderr}"
    [posted_body, stderr, stdout]
  end
end
