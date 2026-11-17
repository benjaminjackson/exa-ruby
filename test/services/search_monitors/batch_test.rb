require "test_helper"

class SearchMonitorsBatchTest < Minitest::Test
  def setup
    super
    @connection = Exa::Connection.build(api_key: "test_key")
    stub_request(:post, "https://api.exa.ai/monitors/batch")
      .to_return(
        status: 200,
        body: { action: "pause", affected: 2, ids: %w[mon_1 mon_2], dry_run: true, has_more: false }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def posted_body
    body = nil
    assert_requested(:post, "https://api.exa.ai/monitors/batch") { |request| body = JSON.parse(request.body) }
    body
  end

  def test_call_posts_snake_case_keys_unchanged
    Exa::Services::SearchMonitors::Batch.new(
      @connection,
      action: "pause",
      filter: { status: "active", metadata: { "team_name" => "research" } },
      dry_run: false,
      limit: 50
    ).call

    expected = {
      "action" => "pause",
      "filter" => { "status" => "active", "metadata" => { "team_name" => "research" } },
      "dry_run" => false,
      "limit" => 50
    }
    assert_equal expected, posted_body
  end

  def test_call_sends_dry_run_true_by_default_and_omits_limit
    Exa::Services::SearchMonitors::Batch.new(@connection, action: "delete", filter: { name: "test" }).call

    assert_equal({ "action" => "delete", "filter" => { "name" => "test" }, "dry_run" => true }, posted_body)
  end

  def test_call_sends_dry_run_true_for_any_value_other_than_false
    Exa::Services::SearchMonitors::Batch.new(@connection, action: "delete", filter: {}, dry_run: nil).call

    assert_equal true, posted_body["dry_run"]
  end

  def test_call_returns_batch_result
    result = Exa::Services::SearchMonitors::Batch.new(@connection, action: "pause", filter: {}).call

    assert_instance_of Exa::Resources::SearchMonitorBatchResult, result
    assert_equal 2, result.affected
    assert_equal %w[mon_1 mon_2], result.ids
    assert_equal true, result.dry_run
    assert_equal false, result.has_more
  end
end
