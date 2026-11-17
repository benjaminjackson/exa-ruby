# frozen_string_literal: true

require "dotenv/load"

require_relative "exa/version"
require_relative "exa/error"
require_relative "exa/middleware/raise_error"
require_relative "exa/connection"
require_relative "exa/resources/search_result"
require_relative "exa/resources/find_similar_result"
require_relative "exa/resources/contents_result"
require_relative "exa/resources/agent_run"
require_relative "exa/resources/agent_run_deletion"
require_relative "exa/resources/agent_run_list"
require_relative "exa/resources/agent_run_event_list"
require_relative "exa/resources/search_monitor"
require_relative "exa/resources/search_monitor_list"
require_relative "exa/resources/search_monitor_run"
require_relative "exa/resources/search_monitor_batch_result"
require_relative "exa/resources/search_monitor_trigger_result"
require_relative "exa/resources/answer"
require_relative "exa/resources/context_result"
require_relative "exa/services/search"
require_relative "exa/services/find_similar"
require_relative "exa/services/get_contents"
require_relative "exa/services/agent_run_create"
require_relative "exa/services/agent_run_stream"
require_relative "exa/services/agent_run_get"
require_relative "exa/services/agent_run_list"
require_relative "exa/services/agent_run_cancel"
require_relative "exa/services/agent_run_stop"
require_relative "exa/services/agent_run_delete"
require_relative "exa/services/agent_run_events"
require_relative "exa/services/search_monitors/create"
require_relative "exa/services/search_monitors/list"
require_relative "exa/services/search_monitors/get"
require_relative "exa/services/search_monitors/update"
require_relative "exa/services/search_monitors/delete"
require_relative "exa/services/search_monitors/trigger"
require_relative "exa/services/search_monitors/batch"
require_relative "exa/services/search_monitors/runs_list"
require_relative "exa/services/search_monitors/runs_get"
require_relative "exa/services/answer"
require_relative "exa/services/answer_stream"
require_relative "exa/services/search_stream"
require_relative "exa/services/context"
require_relative "exa/client"
require_relative "exa/cli/base"
require_relative "exa/cli/request_printer"
require_relative "exa/cli/polling"
require_relative "exa/cli/error_handler"
require_relative "exa/cli/formatters/search_formatter"
require_relative "exa/cli/formatters/context_formatter"
require_relative "exa/cli/formatters/contents_formatter"
require_relative "exa/cli/formatters/agent_run_formatter"
require_relative "exa/cli/formatters/search_monitor_formatter"
require_relative "exa/cli/formatters/answer_formatter"

module Exa
  # Module-level configuration
  class << self
    attr_accessor :api_key, :base_url, :timeout

    def configure
      yield self
    end

    def reset
      self.api_key = nil
      self.base_url = DEFAULT_BASE_URL
      self.timeout = DEFAULT_TIMEOUT
    end
  end

  # Constants for default values
  DEFAULT_BASE_URL = "https://api.exa.ai"
  DEFAULT_TIMEOUT = 30

  # Set defaults
  self.base_url = DEFAULT_BASE_URL
  self.timeout = DEFAULT_TIMEOUT
end
