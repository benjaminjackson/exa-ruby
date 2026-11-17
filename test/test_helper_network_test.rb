# frozen_string_literal: true

require_relative "test_helper"

# Checks that the test helper blocks real network calls in the default run.
# A request that no stub matches, made outside a VCR cassette, must raise
# instead of reaching api.exa.ai.
class TestHelperNetworkTest < Minitest::Test
  BLOCKED_REQUEST_ERRORS = [WebMock::NetConnectNotAllowedError, VCR::Errors::UnhandledHTTPRequestError].freeze

  def test_unstubbed_request_outside_cassette_raises_instead_of_reaching_network
    skip "Real connections are allowed in integration runs" if ENV["RUN_INTEGRATION_TESTS"] == "true"

    client = Exa::Client.new(api_key: "test_key", base_url: "https://api.exa.ai")

    assert_raises(*BLOCKED_REQUEST_ERRORS) do
      client.search("AI/ML infrastructure startups with Series A funding")
    end
  end

  # A cassette opened with its own record mode can send a request that does
  # not match the recording to the live API. Every cassette must use the
  # default mode set in test_helper.rb.
  def test_no_test_opens_a_cassette_with_its_own_record_mode
    offenders = Dir[File.join(__dir__, "**", "*_test.rb")].flat_map do |path|
      File.readlines(path).each_with_index.filter_map do |line, index|
        "#{path}:#{index + 1}" if line.match?(/use_cassette\(.*record:/)
      end
    end

    assert_empty offenders
  end
end
