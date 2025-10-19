# frozen_string_literal: true

module Exa
  module CLI
    module Formatters
      class ContentsFormatter
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
          result.results.each_with_index do |content, idx|
            output << "=== Content #{idx + 1} ==="
            output << "URL:   #{content['url']}"
            output << "Title: #{content['title']}"
            output << ""
            output << "Text:"
            output << "-" * 40
            text = content['text'] || content['content'] || "(No text available)"
            # Truncate long text to first 500 chars
            truncated = text.length > 500 ? text[0..500] + "..." : text
            output << truncated
            output << ""
          end
          output.join("\n")
        end

        def self.format_text(result)
          output = []
          result.results.each do |content|
            output << "#{content['url']}\n#{content['text'] || '(No text available)'}"
          end
          output.join("\n\n")
        end
      end
    end
  end
end
