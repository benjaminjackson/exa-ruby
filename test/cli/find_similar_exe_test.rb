# frozen_string_literal: true

require "test_helper"

class Exa::CLI::FindSimilarExeTest < Minitest::Test
  # exa-ai-find-similar has its own category check. It must reject
  # --category github and exit before it sends a request. The stub keeps
  # the request local if the check ever stops working.
  def test_exe_rejects_category_github
    stub_request(:post, "https://api.exa.ai/findSimilar")
      .to_return(status: 200, body: { results: [] }.to_json, headers: { "Content-Type" => "application/json" })

    _stdout, stderr, exit_status = run_exe_in_process(
      "exa-ai-find-similar", "https://arxiv.org/abs/2307.06435",
      "--category", "github", "--api-key", "test_key"
    )

    assert_equal 1, exit_status
    assert_includes stderr, "Category must be one of"
    assert_not_requested :post, "https://api.exa.ai/findSimilar"
  end
end
