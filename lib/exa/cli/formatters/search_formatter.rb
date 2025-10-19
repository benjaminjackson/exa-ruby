# frozen_string_literal: true

module Exa
  module CLI
    module Formatters
      class SearchFormatter
        def self.format(result, format)
          case format
          when "json"
            JSON.pretty_generate(result.to_h)
          when "pretty"
            format_pretty(result)
          when "text"
            format_text(result)
          else
            JSON.pretty_generate(result.to_h)
          end
        end

        private

        def self.format_pretty(result)
          output = []
          result.results.each_with_index do |item, idx|
            output << "--- Result #{idx + 1} ---"
            output << "Title:       #{item['title']}"
            output << "URL:         #{item['url']}"
            output << "Score:       #{item['score']}" if item['score']
            output << ""
          end
          output.join("\n")
        end

        def self.format_text(result)
          output = []
          result.results.each do |item|
            output << "#{item['title']}\n#{item['url']}"
          end
          output.join("\n\n")
        end
      end
    end
  end
end
