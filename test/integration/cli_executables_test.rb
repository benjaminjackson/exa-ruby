# frozen_string_literal: true

require "test_helper"
require "open3"

# Integration tests for CLI executables
# These tests verify that each executable can be loaded and run without hitting remote endpoints
class CLIExecutablesTest < Minitest::Test
  def setup
    super
    skip_unless_integration_enabled
  end
  # Helper to run an executable and return stdout, stderr, and status
  def run_executable(command)
    stdout, stderr, status = Open3.capture3(command)
    [stdout, stderr, status]
  end

  # Main dispatcher executable
  def test_exa_ai_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai --help")

    assert status.success?, "exa-ai --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Exa CLI"
    assert_includes stdout, "Core Search:"
    assert_includes stdout, "search"
    assert_includes stdout, "answer"
    assert_includes stdout, "context"
  end

  def test_exa_ai_version
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai --version")

    assert status.success?, "exa-ai --version should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_match(/\d+\.\d+\.\d+/, stdout)
  end

  # Search command
  def test_search_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-search --help")

    assert status.success?, "exa-ai-search --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "search"
    assert_includes stdout, "QUERY"
  end

  # Search monitor commands (the /monitors API)
  def test_search_monitor_create_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-search-monitor-create --help")

    assert status.success?, "exa-ai-search-monitor-create --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage: exa-ai search-monitor-create"
  end

  def test_search_monitor_list_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-search-monitor-list --help")

    assert status.success?, "exa-ai-search-monitor-list --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage: exa-ai search-monitor-list"
  end

  def test_search_monitor_get_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-search-monitor-get --help")

    assert status.success?, "exa-ai-search-monitor-get --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage: exa-ai search-monitor-get"
  end

  def test_search_monitor_update_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-search-monitor-update --help")

    assert status.success?, "exa-ai-search-monitor-update --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage: exa-ai search-monitor-update"
  end

  def test_search_monitor_delete_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-search-monitor-delete --help")

    assert status.success?, "exa-ai-search-monitor-delete --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage: exa-ai search-monitor-delete"
  end

  def test_search_monitor_trigger_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-search-monitor-trigger --help")

    assert status.success?, "exa-ai-search-monitor-trigger --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage: exa-ai search-monitor-trigger"
  end

  def test_search_monitor_batch_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-search-monitor-batch --help")

    assert status.success?, "exa-ai-search-monitor-batch --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage: exa-ai search-monitor-batch"
  end

  def test_search_monitor_runs_list_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-search-monitor-runs-list --help")

    assert status.success?, "exa-ai-search-monitor-runs-list --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage: exa-ai search-monitor-runs-list"
  end

  def test_search_monitor_runs_get_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-search-monitor-runs-get --help")

    assert status.success?, "exa-ai-search-monitor-runs-get --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage: exa-ai search-monitor-runs-get"
  end

  # Answer command
  def test_answer_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-answer --help")

    assert status.success?, "exa-ai-answer --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "answer"
    assert_includes stdout, "QUERY"
    assert_includes stdout, "--stream"
    assert_includes stdout, "--output-schema"
  end

  # Context command
  def test_context_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-context --help")

    assert status.success?, "exa-ai-context --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "context"
    assert_includes stdout, "query"
  end

  # Get contents command
  def test_get_contents_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-get-contents --help")

    assert status.success?, "exa-ai-get-contents --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "get-contents"
  end

  # Test that main dispatcher can route to subcommands
  def test_dispatcher_routes_to_search_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai search --help")

    assert status.success?, "exa-ai search --help should route correctly. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "search"
  end

  def test_dispatcher_routes_to_answer_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai answer --help")

    assert status.success?, "exa-ai answer --help should route correctly. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "answer"
  end

  def test_agent_run_stop_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai-agent-run-stop --help")

    assert status.success?, "exa-ai-agent-run-stop --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage: exa-ai agent-run-stop"
  end

  def test_dispatcher_routes_to_agent_run_stop_help
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai agent-run-stop --help")

    assert status.success?, "exa-ai agent-run-stop --help should exit successfully. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stdout, "Usage: exa-ai agent-run-stop"
  end

  # Test error handling for invalid commands
  def test_invalid_command_shows_error
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai invalid-command")

    refute status.success?, "Invalid command should exit with error. stderr: #{stderr}, stdout: #{stdout}"
    # Error message could be in stdout or stderr
    combined_output = stdout + stderr
    assert_includes combined_output, "Unknown command"
  end

  def test_retired_research_command_points_to_agent_run_create
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai research-start --instructions 'Compare honeypot ant species'")

    refute status.success?, "research-start should exit with error. stderr: #{stderr}, stdout: #{stdout}"
    assert_includes stderr, "agent-run-create --query"
  end
end
