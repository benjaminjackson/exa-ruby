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
            output << "Completed: #{run.completed_at}" if run.completed_at
          when "failed"
            output << "Run failed"
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
            output << "Stop reason: #{run.stop_reason}"
          end
          output.join("\n")
        end

        # Flattens an output.grounding array into displayable source strings,
        # tolerating both shapes seen from the API: flat {url,title} items and
        # nested {citations:[{url,title}]} items.
        def self.grounding_sources(run)
          grounding = run.output.is_a?(Hash) ? (run.output["grounding"] || run.output[:grounding]) : nil
          Array(grounding).flat_map do |item|
            citations = item.is_a?(Hash) && item["citations"] ? item["citations"] : [item]
            citations.map { |c| c.is_a?(Hash) ? (c["title"] || c["url"]) : c }
          end.compact
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
