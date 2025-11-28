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
            JSON.pretty_generate(collection.to_h)
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
      end
    end
  end
end
