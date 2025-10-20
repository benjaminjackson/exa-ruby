# frozen_string_literal: true

require_relative "exa/version"
require_relative "exa/error"
require_relative "exa/middleware/raise_error"
require_relative "exa/connection"
require_relative "exa/resources/search_result"
require_relative "exa/resources/find_similar_result"
require_relative "exa/resources/contents_result"
require_relative "exa/resources/research_task"
require_relative "exa/resources/research_list"
require_relative "exa/resources/answer"
require_relative "exa/resources/context_result"
require_relative "exa/services/search"
require_relative "exa/services/find_similar"
require_relative "exa/services/get_contents"
require_relative "exa/services/research_get"
require_relative "exa/services/research_start"
require_relative "exa/services/research_list"
require_relative "exa/services/answer"
require_relative "exa/services/answer_stream"
require_relative "exa/services/context"
require_relative "exa/client"
require_relative "exa/cli/base"
require_relative "exa/cli/polling"
require_relative "exa/cli/error_handler"
require_relative "exa/cli/formatters/search_formatter"
require_relative "exa/cli/formatters/context_formatter"
require_relative "exa/cli/formatters/contents_formatter"
require_relative "exa/cli/formatters/research_formatter"

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
