# frozen_string_literal: true

module Exa
  module CLI
    module Formatters
      class WebsetFormatter
        def self.format(webset, output_format)
          case output_format
          when "json"
            JSON.generate(webset.to_h)
          when "pretty"
            JSON.pretty_generate(webset.to_h)
          when "text"
            format_as_text(webset)
          when "toon"
            Exa::CLI::Base.encode_as_toon(webset.to_h)
          else
            raise ArgumentError, "Unknown output format: #{output_format}"
          end
        end

        def self.format_collection(collection, output_format)
          case output_format
          when "json"
            JSON.generate(collection.to_h)
          when "pretty"
            format_collection_as_pretty(collection)
          when "text"
            format_collection_as_text(collection)
          when "toon"
            Exa::CLI::Base.encode_as_toon(collection.to_h)
          else
            raise ArgumentError, "Unknown output format: #{output_format}"
          end
        end

        def self.format_as_text(webset)
          lines = []
          lines << "Webset: #{webset.id}"
          lines << "Status: #{webset.status}"
          lines << "Created: #{webset.created_at}" if webset.created_at
          lines << "Updated: #{webset.updated_at}" if webset.updated_at

          if webset.searches && !webset.searches.empty?
            lines << "\nSearches:"
            webset.searches.each do |search|
              lines << "  - #{search['query']}" if search['query']
            end
          end

          if webset.enrichments && !webset.enrichments.empty?
            lines << "\nEnrichments: #{webset.enrichments.length}"
          end

          lines.join("\n")
        end
        private_class_method :format_as_text

        def self.format_collection_as_text(collection)
          lines = ["Websets (#{collection.data.length} items):"]
          collection.data.each do |ws|
            lines << "\n  #{ws['id']}"
            lines << "  Status: #{ws['status']}"
            lines << "  Created: #{ws['createdAt']}" if ws['createdAt']
          end
          lines.join("\n")
        end
        private_class_method :format_collection_as_text

        def self.format_collection_as_pretty(collection)
          lines = []

          # Header with count and pagination info
          header = "Websets (#{collection.data.length} items)"
          header += " - Page #{collection.has_more ? '1 of many' : '1 of 1'}" if collection.data.any?
          lines << header

          if collection.has_more
            lines << "Next Cursor:   #{collection.next_cursor}"
          end

          lines << ""

          # Format each webset
          collection.data.each_with_index do |ws, idx|
            lines << "" if idx > 0  # Blank line between websets

            lines << "Webset ID:     #{ws['id']}"
            lines << "Status:        #{ws['status']}"
            lines << "Title:         #{ws['title']}" if ws['title']
            lines << "External ID:   #{ws['externalId']}" if ws['externalId']
            lines << "Created:       #{ws['createdAt']}" if ws['createdAt']
            lines << "Updated:       #{ws['updatedAt']}" if ws['updatedAt']

            # Searches
            if ws['searches'] && !ws['searches'].empty?
              lines << ""
              lines << "Searches (#{ws['searches'].length}):"
              ws['searches'].each do |search|
                status_indicator = case search['status']
                                   when 'completed' then '✓'
                                   when 'running' then '→'
                                   when 'failed' then '✗'
                                   else '•'
                                   end
                lines << "  #{status_indicator} #{search['query']} (#{search['status']})" if search['query']
              end
            end

            # Enrichments
            if ws['enrichments'] && !ws['enrichments'].empty?
              lines << "Enrichments:   #{ws['enrichments'].length}"
            end

            # Monitors
            if ws['monitors'] && !ws['monitors'].empty?
              lines << "Monitors:      #{ws['monitors'].length}"
            end

            # Imports
            if ws['imports'] && !ws['imports'].empty?
              lines << "Imports:       #{ws['imports'].length}"
            end
          end

          lines.join("\n")
        end
        private_class_method :format_collection_as_pretty
      end
    end
  end
end
