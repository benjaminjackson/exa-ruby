# frozen_string_literal: true

require "test_helper"
require "open3"

# Integration tests for CLI executables
# These tests verify that each executable can be loaded and run without hitting remote endpoints
class CLIExecutablesTest < Minitest::Test
  def setup
    skip_unless_integration_enabled
  end
  # Helper to run an executable and return stdout, stderr, and status
  def run_executable(command)
    stdout, stderr, status = Open3.capture3(command)
    [stdout, stderr, status]
  end

  # Main dispatcher executable
  def test_exa_ai_help
    stdout, _stderr, status = run_executable("bundle exec exe/exa-ai --help")

    assert status.success?, "exa-ai --help should exit successfully"
    assert_includes stdout, "Exa CLI"
    assert_includes stdout, "Core Search:"
    assert_includes stdout, "search"
    assert_includes stdout, "answer"
    assert_includes stdout, "context"
  end

  def test_exa_ai_version
    stdout, _stderr, status = run_executable("bundle exec exe/exa-ai --version")

    assert status.success?, "exa-ai --version should exit successfully"
    assert_match(/\d+\.\d+\.\d+/, stdout)
  end

  # Search command
  def test_search_help
    stdout, _stderr, status = run_executable("bundle exec exe/exa-ai-search --help")

    assert status.success?, "exa-ai-search --help should exit successfully"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "search"
    assert_includes stdout, "QUERY"
  end

  # Answer command
  def test_answer_help
    stdout, _stderr, status = run_executable("bundle exec exe/exa-ai-answer --help")

    assert status.success?, "exa-ai-answer --help should exit successfully"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "answer"
    assert_includes stdout, "QUERY"
    assert_includes stdout, "--stream"
    assert_includes stdout, "--output-schema"
  end

  # Context command
  def test_context_help
    stdout, _stderr, status = run_executable("bundle exec exe/exa-ai-context --help")

    assert status.success?, "exa-ai-context --help should exit successfully"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "context"
    assert_includes stdout, "query"
  end

  # Get contents command
  def test_get_contents_help
    stdout, _stderr, status = run_executable("bundle exec exe/exa-ai-get-contents --help")

    assert status.success?, "exa-ai-get-contents --help should exit successfully"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "get-contents"
  end

  # Research start command
  def test_research_start_help
    stdout, _stderr, status = run_executable("bundle exec exe/exa-ai-research-start --help")

    assert status.success?, "exa-ai-research-start --help should exit successfully"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "research-start"
    assert_includes stdout, "--instructions"
  end

  # Research get command
  def test_research_get_help
    stdout, _stderr, status = run_executable("bundle exec exe/exa-ai-research-get --help")

    assert status.success?, "exa-ai-research-get --help should exit successfully"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "research-get"
    assert_includes stdout, "research_id"
  end

  # Research list command
  def test_research_list_help
    stdout, _stderr, status = run_executable("bundle exec exe/exa-ai-research-list --help")

    assert status.success?, "exa-ai-research-list --help should exit successfully"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "research-list"
  end

  # Test that main dispatcher can route to subcommands
  def test_dispatcher_routes_to_search_help
    stdout, _stderr, status = run_executable("bundle exec exe/exa-ai search --help")

    assert status.success?, "exa-ai search --help should route correctly"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "search"
  end

  def test_dispatcher_routes_to_answer_help
    stdout, _stderr, status = run_executable("bundle exec exe/exa-ai answer --help")

    assert status.success?, "exa-ai answer --help should route correctly"
    assert_includes stdout, "Usage:"
    assert_includes stdout, "answer"
  end

  # Test error handling for invalid commands
  def test_invalid_command_shows_error
    stdout, stderr, status = run_executable("bundle exec exe/exa-ai invalid-command")

    refute status.success?, "Invalid command should exit with error"
    # Error message could be in stdout or stderr
    combined_output = stdout + stderr
    assert_includes combined_output, "Unknown command"
  end
end
