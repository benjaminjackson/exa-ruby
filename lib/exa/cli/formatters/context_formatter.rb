# frozen_string_literal: true

require "json"

module Exa
  module CLI
    module Formatters
      class ContextFormatter
        def self.format(result, format)
          case format
          when "json"
            JSON.pretty_generate(result.to_h)
          when "text"
            format_text(result)
          else
            JSON.pretty_generate(result.to_h)
          end
        end

        private

        def self.format_text(result)
          output = []
          output << "Query: #{result.query}"
          output << "Request ID: #{result.request_id}"
          output << "Results: #{result.results_count}"
          output << "Cost: $#{result.cost_dollars}"
          output << "Search Time: #{result.search_time}ms"
          output << ""
          output << "Code Context:"
          output << "-" * 40
          output << result.response.to_s
          output.join("\n")
        end
      end
    end
  end
end
