# frozen_string_literal: true

module Exa
  module CLI
    module Formatters
      class MonitorFormatter
        def self.format(monitor, output_format)
          case output_format
          when "json"
            JSON.generate(monitor.to_h)
          when "pretty"
            format_as_pretty(monitor)
          when "text"
            format_as_text(monitor)
          when "toon"
            Exa::CLI::Base.encode_as_toon(monitor.to_h)
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

        def self.format_as_pretty(monitor)
          lines = []
          lines << "Monitor ID:    #{monitor.id}"
          lines << "Webset ID:     #{monitor.webset_id}" if monitor.webset_id
          lines << "Status:        #{monitor.status}"

          if monitor.cadence
            lines << ""
            lines << "Cadence:"
            lines << "  Cron:        #{monitor.cadence['cron']}" if monitor.cadence['cron']
            lines << "  Timezone:    #{monitor.cadence['timezone']}" if monitor.cadence['timezone']
          end

          if monitor.behavior
            lines << ""
            lines << "Behavior:"
            lines << "  Type:        #{monitor.behavior['type']}" if monitor.behavior['type']
            lines << "  Query:       #{monitor.behavior['query']}" if monitor.behavior['query']
            lines << "  Count:       #{monitor.behavior['count']}" if monitor.behavior['count']
          end

          lines << ""
          lines << "Created:       #{monitor.created_at}" if monitor.created_at
          lines << "Updated:       #{monitor.updated_at}" if monitor.updated_at

          lines.join("\n")
        end
        private_class_method :format_as_pretty

        def self.format_as_text(monitor)
          lines = []
          lines << "Monitor: #{monitor.id}"
          lines << "Webset: #{monitor.webset_id}" if monitor.webset_id
          lines << "Status: #{monitor.status}"

          if monitor.cadence
            lines << "\nCadence:"
            lines << "  Cron: #{monitor.cadence['cron']}" if monitor.cadence['cron']
            lines << "  Timezone: #{monitor.cadence['timezone']}" if monitor.cadence['timezone']
          end

          if monitor.behavior
            lines << "\nBehavior:"
            lines << "  Type: #{monitor.behavior['type']}" if monitor.behavior['type']
            lines << "  Query: #{monitor.behavior['query']}" if monitor.behavior['query']
            lines << "  Count: #{monitor.behavior['count']}" if monitor.behavior['count']
          end

          lines << "\nCreated: #{monitor.created_at}" if monitor.created_at
          lines << "Updated: #{monitor.updated_at}" if monitor.updated_at

          lines.join("\n")
        end
        private_class_method :format_as_text

        def self.format_collection_as_pretty(collection)
          lines = []
          lines << "Monitors (#{collection.data.length} items)"
          lines << ""

          collection.data.each_with_index do |mon, idx|
            lines << "" if idx > 0  # Blank line between monitors

            lines << "Monitor ID:    #{mon['id']}"
            lines << "Webset ID:     #{mon['websetId']}" if mon['websetId']
            lines << "Status:        #{mon['status']}"

            if mon['cadence']
              lines << "Cron:          #{mon['cadence']['cron']}" if mon['cadence']['cron']
              lines << "Timezone:      #{mon['cadence']['timezone']}" if mon['cadence']['timezone']
            end

            if mon['behavior']
              lines << "Query:         #{mon['behavior']['query']}" if mon['behavior']['query']
            end

            lines << "Created:       #{mon['createdAt']}" if mon['createdAt']
            lines << "Updated:       #{mon['updatedAt']}" if mon['updatedAt']
          end

          if collection.has_more
            lines << ""
            lines << "Next Cursor:   #{collection.next_cursor}"
          end

          lines.join("\n")
        end
        private_class_method :format_collection_as_pretty

        def self.format_collection_as_text(collection)
          lines = ["Monitors (#{collection.data.length} items):"]
          collection.data.each do |mon|
            lines << "\n  #{mon['id']}"
            lines << "  Status: #{mon['status']}"
            lines << "  Webset: #{mon['websetId']}" if mon['websetId']
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
