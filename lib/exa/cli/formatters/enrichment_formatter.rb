# frozen_string_literal: true

module Exa
  module CLI
    module Formatters
      class EnrichmentFormatter
        def self.format(enrichment, output_format)
          case output_format
          when "json"
            JSON.generate(enrichment.to_h)
          when "pretty"
            JSON.pretty_generate(enrichment.to_h)
          when "text"
            format_as_text(enrichment)
          when "toon"
            Exa::CLI::Base.encode_as_toon(enrichment.to_h)
          else
            raise ArgumentError, "Unknown output format: #{output_format}"
          end
        end

        def self.format_collection(collection, output_format)
          case output_format
          when "json"
            JSON.generate(collection.to_h)
          when "pretty"
            JSON.pretty_generate(collection.to_h)
          when "text"
            format_collection_as_text(collection)
          when "toon"
            Exa::CLI::Base.encode_as_toon(collection.to_h)
          else
            raise ArgumentError, "Unknown output format: #{output_format}"
          end
        end

        def self.format_as_text(enrichment)
          lines = []
          lines << "Enrichment: #{enrichment.id}"
          lines << "Webset: #{enrichment.webset_id}" if enrichment.webset_id
          lines << "Status: #{enrichment.status}"
          lines << "Title: #{enrichment.title}" if enrichment.title
          lines << "Description: #{enrichment.description}" if enrichment.description
          lines << "Format: #{enrichment.format}" if enrichment.format

          if enrichment.options && !enrichment.options.empty?
            lines << "\nOptions:"
            enrichment.options.each do |option|
              lines << "  - #{option['label']}" if option['label']
            end
          end

          lines << "Created: #{enrichment.created_at}" if enrichment.created_at
          lines << "Updated: #{enrichment.updated_at}" if enrichment.updated_at

          lines.join("\n")
        end
        private_class_method :format_as_text

        def self.format_collection_as_text(collection)
          lines = ["Enrichments (#{collection.data.length} items):"]
          collection.data.each do |enr|
            lines << "\n  #{enr['id']}"
            lines << "  Status: #{enr['status']}"
            lines << "  Title: #{enr['title']}" if enr['title']
          end
          lines.join("\n")
        end
        private_class_method :format_collection_as_text
      end
    end
  end
end
