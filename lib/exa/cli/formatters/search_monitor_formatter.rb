module Exa
  module CLI
    module Formatters
      # Output for the exa-ai search-monitor-* commands (the /monitors API).
      class SearchMonitorFormatter
        # Format any search monitor result: a monitor, a run, a list of either,
        # a batch result or a trigger result.
        def self.format(result, format)
          case format
          when "pretty" then format_pretty(result)
          when "text" then format_text(result)
          when "toon" then Exa::CLI::Base.encode_as_toon(result.to_h)
          else JSON.pretty_generate(result.to_h)
          end
        end

        def self.format_pretty(result)
          case result
          when Resources::SearchMonitor then format_monitor_pretty(result)
          when Resources::SearchMonitorRun then format_run_pretty(result)
          when Resources::SearchMonitorList then format_list_pretty(result)
          when Resources::SearchMonitorBatchResult then format_batch_pretty(result)
          else JSON.pretty_generate(result.to_h)
          end
        end

        def self.format_text(result)
          case result
          when Resources::SearchMonitorList
            result.data.map { |item| summary_line(item) }.join("\n")
          when Resources::SearchMonitor, Resources::SearchMonitorRun
            summary_line(result)
          else
            result.to_h.map { |key, value| "#{key}: #{value}" }.join("\n")
          end
        end

        def self.format_monitor_pretty(monitor)
          output = []
          output << "Search Monitor: #{monitor.id}"
          output << "Name: #{monitor.name}" if monitor.name
          output << "Status: #{monitor.status}"
          output << "Query: #{monitor.search['query']}" if monitor.search
          output << "Schedule: #{monitor.trigger ? "every #{monitor.trigger['period']}" : 'manual only'}"
          output << "Webhook: #{monitor.webhook['url']}" if monitor.webhook
          output << "Next run: #{monitor.next_run_at}" if monitor.next_run_at
          output << "Created: #{monitor.created_at}" if monitor.created_at
          if monitor.webhook_secret
            output << ""
            output << "Webhook secret: #{monitor.webhook_secret}"
            output << "Save it now. The API returns the webhook secret only once."
          end
          output.join("\n")
        end

        def self.format_run_pretty(run)
          output = []
          output << "Search Monitor Run: #{run.id}"
          output << "Monitor: #{run.monitor_id}"
          output << "Status: #{run.status}"
          output << "Fail reason: #{run.fail_reason}" if run.fail_reason
          output << "Duration: #{run.duration_ms} ms" if run.duration_ms
          output << "Created: #{run.created_at}" if run.created_at
          if run.output
            output << ""
            output << "Output:"
            output << JSON.pretty_generate(run.output)
          end
          output.join("\n")
        end

        def self.format_list_pretty(list)
          return "No results found." if list.data.empty?

          lines = list.data.map { |item| summary_line(item) }
          lines << "" << "More results available. Use --cursor #{list.next_cursor} for next page." if list.has_more
          lines.join("\n")
        end

        def self.format_batch_pretty(result)
          output = []
          output << (result.dry_run ? "Dry run: nothing changed. Pass --execute to apply." : "Batch #{result.action} applied.")
          output << "Action: #{result.action}"
          output << "Affected: #{result.affected}"
          output << "IDs: #{Array(result.ids).join(', ')}" unless Array(result.ids).empty?
          output << "More monitors match. Run the command again." if result.has_more
          output.join("\n")
        end

        # One line per monitor or run: id, status, then the name or creation time.
        def self.summary_line(item)
          label = item.is_a?(Resources::SearchMonitor) ? item.name : item.created_at
          [item.id, item.status, label].compact.join("  ")
        end
      end
    end
  end
end
