# frozen_string_literal: true

module Exa
  module CLI
    module Formatters
      class WebsetSearchFormatter
        def self.format(search, format)
          case format
          when "json"
            JSON.pretty_generate(search.to_h)
          when "pretty"
            format_pretty(search)
          when "text"
            format_text(search)
          when "toon"
            Exa::CLI::Base.encode_as_toon(search.to_h)
          else
            JSON.pretty_generate(search.to_h)
          end
        end

        private

        def self.format_pretty(search)
          output = []
          output << "Search ID:       #{search.id}"
          output << "Status:          #{search.status}"
          output << "Query:           #{search.query}"
          output << "Entity Type:     #{search.entity&.[]('type') || 'N/A'}" if search.entity
          output << "Count:           #{search.count}" if search.count
          output << "Behavior:        #{search.behavior}"
          output << "Recall:          #{search.recall}" if search.recall
          output << "Created:         #{search.created_at}"
          output << "Updated:         #{search.updated_at}"
          output << "Progress:        #{search.progress}" if search.progress
          output << ""

          if search.canceled?
            output << "Canceled:        #{search.canceled_at}"
            output << "Cancel Reason:   #{search.canceled_reason}" if search.canceled_reason
          end

          output.join("\n")
        end

        def self.format_text(search)
          [
            "ID: #{search.id}",
            "Status: #{search.status}",
            "Query: #{search.query}",
            "Behavior: #{search.behavior}"
          ].join("\n")
        end
      end
    end
  end
end
