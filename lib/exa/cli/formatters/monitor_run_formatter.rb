# frozen_string_literal: true

module Exa
  module CLI
    module Formatters
      class MonitorRunFormatter
        def self.format(monitor_run, output_format)
          case output_format
          when "json"
            JSON.generate(monitor_run.to_h)
          when "pretty"
            JSON.pretty_generate(monitor_run.to_h)
          when "text"
            format_as_text(monitor_run)
          when "toon"
            Exa::CLI::Base.encode_as_toon(monitor_run.to_h)
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

        def self.format_as_text(monitor_run)
          lines = []
          lines << "Monitor Run: #{monitor_run.id}"
          lines << "Monitor: #{monitor_run.monitor_id}" if monitor_run.monitor_id
          lines << "Status: #{monitor_run.status}"

          lines << "\nCreated: #{monitor_run.created_at}" if monitor_run.created_at
          lines << "Updated: #{monitor_run.updated_at}" if monitor_run.updated_at
          lines << "Completed: #{monitor_run.completed_at}" if monitor_run.completed_at

          if monitor_run.failed?
            lines << "Failed: #{monitor_run.failed_at}" if monitor_run.failed_at
            lines << "Reason: #{monitor_run.failed_reason}" if monitor_run.failed_reason
          end

          lines.join("\n")
        end
        private_class_method :format_as_text

        def self.format_collection_as_text(collection)
          lines = ["Monitor Runs (#{collection.data.length} items):"]
          collection.data.each do |run|
            lines << "\n  #{run['id']}"
            lines << "  Status: #{run['status']}"
            lines << "  Completed: #{run['completedAt']}" if run['completedAt']
            lines << "  Failed: #{run['failedReason']}" if run['failedReason']
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
