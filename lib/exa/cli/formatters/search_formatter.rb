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
          when "toon"
            Exa::CLI::Base.encode_as_toon(result.to_h)
          else
            JSON.pretty_generate(result.to_h)
          end
        end

        # Writes one line per API warning to io (stderr by default). The API
        # says warnings are for logs, not for a model, so they stay out of
        # stdout in every output format.
        def self.print_warnings(result, io = $stderr)
          (result.warnings || []).each do |warning|
            io.puts "Warning: #{warning['message']} (#{warning['path']})"
          end
        end

        private

        # Notices are written for a model to read, so pretty and text output
        # show them above the results.
        def self.notice_lines(result)
          (result.notices || []).map { |notice| "Notice: #{notice['message']}" }
        end

        def self.format_pretty(result)
          output = notice_lines(result)
          output << "" if output.any?
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
          output = notice_lines(result)
          result.results.each do |item|
            output << "#{item['title']}\n#{item['url']}"
          end
          output.join("\n\n")
        end
      end
    end
  end
end
