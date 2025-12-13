# frozen_string_literal: true

module Exa
  module CLI
    module Formatters
      class WebsetItemFormatter
        def self.format(item, output_format)
          case output_format
          when "json"
            JSON.generate(item)
          when "pretty"
            format_as_pretty(item)
          when "text"
            format_as_text(item)
          when "toon"
            Exa::CLI::Base.encode_as_toon(item)
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

        def self.format_as_pretty(item)
          lines = []
          lines << "Item ID:       #{item['id']}"
          lines << "URL:           #{item['url']}" if item['url']
          lines << "Title:         #{item['title']}" if item['title']
          lines << "Status:        #{item['status']}" if item['status']
          lines << "Created:       #{item['createdAt']}" if item['createdAt']
          lines << "Updated:       #{item['updatedAt']}" if item['updatedAt']

          if item['entity']
            lines << ""
            lines << "Entity:"
            lines << "  Type:        #{item['entity']['type']}" if item['entity']['type']
            lines << "  Name:        #{item['entity']['name']}" if item['entity']['name']
            lines << "  Description: #{item['entity']['description']}" if item['entity']['description']
          end

          lines.join("\n")
        end
        private_class_method :format_as_pretty

        def self.format_as_text(item)
          lines = []
          lines << "Item: #{item['id']}"
          lines << "URL: #{item['url']}" if item['url']
          lines << "Title: #{item['title']}" if item['title']
          lines << "Status: #{item['status']}" if item['status']
          lines << "Created: #{item['createdAt']}" if item['createdAt']
          lines << "Updated: #{item['updatedAt']}" if item['updatedAt']

          if item['entity']
            lines << "\nEntity:"
            lines << "  Type: #{item['entity']['type']}" if item['entity']['type']
            lines << "  Name: #{item['entity']['name']}" if item['entity']['name']
          end

          lines.join("\n")
        end
        private_class_method :format_as_text

        def self.format_collection_as_pretty(collection)
          lines = []
          lines << "Webset Items (#{collection.data.length} items)"

          if collection.has_more
            lines << "Next Cursor:   #{collection.next_cursor}"
          end

          lines << ""

          collection.data.each_with_index do |item, idx|
            lines << "" if idx > 0  # Blank line between items

            lines << "Item ID:       #{item['id']}"
            lines << "URL:           #{item['url']}" if item['url']
            lines << "Title:         #{item['title']}" if item['title']
            lines << "Status:        #{item['status']}" if item['status']
            lines << "Created:       #{item['createdAt']}" if item['createdAt']
            lines << "Updated:       #{item['updatedAt']}" if item['updatedAt']

            if item['entity']
              entity_name = item['entity']['name']
              entity_type = item['entity']['type']
              lines << "Entity:        #{entity_name}" if entity_name
              lines << "Entity Type:   #{entity_type}" if entity_type && !entity_name
            end
          end

          lines.join("\n")
        end
        private_class_method :format_collection_as_pretty

        def self.format_collection_as_text(collection)
          lines = ["Webset Items (#{collection.data.length} items):"]
          collection.data.each_with_index do |item, idx|
            lines << "\n#{idx + 1}. #{item['id']}"
            lines << "   URL: #{item['url']}" if item['url']
            lines << "   Title: #{item['title']}" if item['title']
            lines << "   Status: #{item['status']}" if item['status']
            if item['entity'] && item['entity']['name']
              lines << "   Entity: #{item['entity']['name']}"
            end
          end

          if collection.has_more
            lines << "\nMore available (cursor: #{collection.next_cursor})"
          end

          lines.join("\n")
        end
        private_class_method :format_collection_as_text
      end
    end
  end
end
