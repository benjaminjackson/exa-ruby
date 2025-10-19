# frozen_string_literal: true

module Exa
  module CLI
    module Formatters
      class AnswerFormatter
        def self.format(result, format)
          case format
          when "json"
            JSON.pretty_generate(result.to_h)
          when "pretty"
            format_pretty(result)
          else
            JSON.pretty_generate(result.to_h)
          end
        end

        private

        def self.format_pretty(result)
          output = []
          output << "Answer:"
          output << "-" * 60
          output << result.answer
          output << ""

          if result.citations && !result.citations.empty?
            output << "Citations:"
            output << "-" * 60
            result.citations.each_with_index do |citation, idx|
              output << "[#{idx + 1}] #{citation['title']}"
              output << "    URL:      #{citation['url']}"
              output << "    Author:   #{citation['author']}" if citation['author']
              output << "    Date:     #{citation['publishedDate']}" if citation['publishedDate']
              output << ""
            end
          end

          output << "Cost: $#{result.cost_dollars}" if result.cost_dollars

          output.join("\n")
        end
      end
    end
  end
end
