module Exa
  module CLI
    module Formatters
      class AgentRunFormatter
        def self.format_run(run, format)
          case format
          when "json"
            JSON.pretty_generate(run.to_h)
          when "pretty"
            format_run_pretty(run)
          when "text"
            format_run_text(run)
          when "toon"
            Exa::CLI::Base.encode_as_toon(run.to_h)
          else
            JSON.pretty_generate(run.to_h)
          end
        end

        # Formats the result of deleting a run (id, object, deleted).
        def self.format_deletion(deletion, format)
          case format
          when "pretty"
            deletion.deleted? ? "Deleted agent run: #{deletion.id}" : "Agent run not deleted: #{deletion.id}"
          when "text"
            "#{deletion.id} #{deletion.deleted? ? 'DELETED' : 'NOT_DELETED'}"
          when "toon"
            Exa::CLI::Base.encode_as_toon(deletion.to_h)
          else
            JSON.pretty_generate(deletion.to_h)
          end
        end

        def self.format_list(list, format)
          case format
          when "json"
            JSON.pretty_generate(list.to_h)
          when "pretty"
            format_list_pretty(list)
          when "text"
            format_list_text(list)
          when "toon"
            Exa::CLI::Base.encode_as_toon(list.to_h)
          else
            JSON.pretty_generate(list.to_h)
          end
        end

        private

        def self.format_run_pretty(run)
          output = []
          output << "Agent Run: #{run.id}"
          output << "Status: #{run.status.upcase}"
          output << "Created: #{run.created_at}"
          output << ""

          case run.status
          when "queued"
            output << "Run is queued..."
          when "running"
            output << "Run is running... ⚙️"
          when "completed"
            output << "Output:"
            output << "--------"
            if run.output.is_a?(Hash)
              output << (run.output[:text] || run.output["text"] || run.output.inspect)
            else
              output << run.output.to_s
            end
            if run.output.is_a?(Hash) && (structured = run.output["structured"] || run.output[:structured])
              output << ""
              output << "Structured:"
              output << JSON.pretty_generate(structured)
            end
            sources = grounding_sources(run)
            unless sources.empty?
              output << ""
              output << "Grounding:"
              sources.each { |s| output << "  - #{s}" }
            end
            output << ""
            if run.cost_dollars
              total = run.cost_dollars.is_a?(Hash) ? (run.cost_dollars["total"] || run.cost_dollars[:total]) : run.cost_dollars
              output << "Cost: $#{total}"
            end
            data_source_costs = data_source_costs_line(run)
            output << data_source_costs if data_source_costs
            usage = usage_line(run)
            output << usage if usage
            output << "Completed: #{run.completed_at}" if run.completed_at
            output << "Stop reason: #{run.stop_reason}" if run.stop_reason
          when "failed"
            output << "Run failed"
            output << error_line(run) if run.error
            output << "Stop reason: #{run.stop_reason}" if run.stop_reason
          when "cancelled"
            output << "Run was cancelled"
            output << "Completed: #{run.completed_at}" if run.completed_at
          end

          output.join("\n")
        end

        def self.format_list_pretty(list)
          output = []
          output << "Agent Runs (#{list.data.length}):"
          output << ""

          if list.data.empty?
            output << "No runs found."
          else
            output << "%-40s %-15s %s" % ["Run ID", "Status", "Created"]
            output << "-" * 70

            list.data.each do |run|
              run_id = run.id.to_s[0..38]
              status = run.status.upcase[0..14]
              created = run.created_at.to_s[0..19]
              output << "%-40s %-15s %s" % [run_id, status, created]
            end
          end

          output << ""
          if list.has_more
            output << "More results available. Use --cursor #{list.next_cursor} for next page."
          else
            output << "End of results."
          end

          output.join("\n")
        end

        def self.format_run_text(run)
          output = []
          output << "#{run.id} #{run.status.upcase} #{run.created_at}"
          if run.status == "completed" && run.output
            text = run.output.is_a?(Hash) ? (run.output[:text] || run.output["text"]) : run.output.to_s
            output << text.to_s
            if run.output.is_a?(Hash) && (structured = run.output["structured"] || run.output[:structured])
              output << JSON.generate(structured)
            end
          elsif run.status == "failed"
            output << error_line(run) if run.error
          end
          output << "Stop reason: #{run.stop_reason}" if run.stop_reason && %w[completed failed].include?(run.status)
          output.join("\n")
        end

        # One line with a failed run's error type, code and message.
        def self.error_line(run)
          error = run.error
          return "Error: #{error}" unless error.is_a?(Hash)

          "Error: #{error['type']} (#{error['code']}): #{error['message']}"
        end

        # Flattens an output.grounding array into displayable source strings,
        # tolerating both shapes seen from the API: flat {url,title} items and
        # nested {citations:[{url,title}]} items. When an item names the output
        # field it supports, or a confidence, each of its sources ends with
        # "(field: ..., confidence: ...)".
        def self.grounding_sources(run)
          grounding = run.output.is_a?(Hash) ? (run.output["grounding"] || run.output[:grounding]) : nil
          Array(grounding).flat_map do |item|
            citations = item.is_a?(Hash) && item["citations"] ? item["citations"] : [item]
            note = grounding_note(item)
            citations.map do |c|
              source = c.is_a?(Hash) ? (c["title"] || c["url"]) : c
              source && note ? "#{source} (#{note})" : source
            end
          end.compact
        end

        # "field: capital, confidence: high" for a grounding item, or nil when
        # the item has neither.
        def self.grounding_note(item)
          return nil unless item.is_a?(Hash)

          parts = []
          parts << "field: #{item['field']}" if item["field"]
          parts << "confidence: #{item['confidence']}" if item["confidence"]
          parts.empty? ? nil : parts.join(", ")
        end

        # "Data source costs: fiber $0.04, similarweb $0.3" from
        # costDollars.dataSources, or nil when there is none.
        def self.data_source_costs_line(run)
          return nil unless run.cost_dollars.is_a?(Hash)

          costs = run.cost_dollars["dataSources"] || run.cost_dollars[:dataSources]
          return nil unless costs.is_a?(Hash) && costs.any?

          "Data source costs: " + costs.map { |provider, dollars| "#{provider} $#{dollars}" }.join(", ")
        end

        USAGE_LABELS = {
          "agentComputeUnits" => "agent compute units",
          "searches" => "searches",
          "emails" => "emails",
          "phoneNumbers" => "phone numbers"
        }.freeze

        # One line with the usage quantities the run reports, for example
        # "Usage: 12.5 agent compute units, 8 searches, data source calls: fiber 2".
        # Only keys present in run.usage appear. Returns nil when there are none.
        def self.usage_line(run)
          return nil unless run.usage.is_a?(Hash)

          usage = run.usage.transform_keys(&:to_s)
          parts = USAGE_LABELS.filter_map { |key, label| "#{usage[key]} #{label}" if usage.key?(key) }
          calls = usage["dataSources"]
          if calls.is_a?(Hash) && calls.any?
            parts << "data source calls: " + calls.map { |provider, count| "#{provider} #{count}" }.join(", ")
          end
          parts.empty? ? nil : "Usage: #{parts.join(', ')}"
        end

        def self.format_list_text(list)
          output = list.data.map do |run|
            "#{run.id} #{run.status.upcase} #{run.created_at}"
          end
          output.join("\n")
        end
      end
    end
  end
end
