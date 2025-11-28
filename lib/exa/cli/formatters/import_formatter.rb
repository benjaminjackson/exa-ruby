# frozen_string_literal: true

module Exa
  module CLI
    module Formatters
      class ImportFormatter
        def self.format(import, output_format)
          case output_format
          when "json"
            JSON.generate(import.to_h)
          when "pretty"
            JSON.pretty_generate(import.to_h)
          when "text"
            format_as_text(import)
          when "toon"
            Exa::CLI::Base.encode_as_toon(import.to_h)
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

        def self.format_as_text(import)
          lines = []
          lines << "Import: #{import.id}"
          lines << "Status: #{import.status}"
          lines << "Title: #{import.title}" if import.title
          lines << "Format: #{import.format}" if import.format

          if import.entity
            entity_type = import.entity['type'] || import.entity[:type]
            lines << "Entity Type: #{entity_type}" if entity_type
          end

          lines << "Count: #{import.count}" if import.count

          if import.failed?
            lines << "\nFailure Details:"
            lines << "  Reason: #{import.failed_reason}" if import.failed_reason
            lines << "  Message: #{import.failed_message}" if import.failed_message
            lines << "  Failed At: #{import.failed_at}" if import.failed_at
          end

          if import.upload_url
            lines << "\nUpload:"
            lines << "  URL: #{import.upload_url}"
            lines << "  Valid Until: #{import.upload_valid_until}" if import.upload_valid_until
          end

          lines << "\nCreated: #{import.created_at}" if import.created_at
          lines << "Updated: #{import.updated_at}" if import.updated_at

          lines.join("\n")
        end
        private_class_method :format_as_text

        def self.format_collection_as_text(collection)
          lines = ["Imports (#{collection.data.length} items):"]
          collection.data.each do |imp|
            lines << "\n  #{imp.id}"
            lines << "  Status: #{imp.status}"
            lines << "  Title: #{imp.title}" if imp.title
            lines << "  Count: #{imp.count}" if imp.count
          end
          lines.join("\n")
        end
        private_class_method :format_collection_as_text
      end
    end
  end
end
