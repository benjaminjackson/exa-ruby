module Exa
  module CLI
    module Formatters
      class ResearchFormatter
        def self.format_task(task, format, show_events: false)
          case format
          when "json"
            JSON.pretty_generate(task.to_h)
          when "pretty"
            format_task_pretty(task, show_events: show_events)
          when "text"
            format_task_text(task, show_events: show_events)
          else
            JSON.pretty_generate(task.to_h)
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
          else
            JSON.pretty_generate(list.to_h)
          end
        end

        private

        def self.format_task_pretty(task, show_events: false)
          output = []
          output << "Research Task: #{task.research_id}"
          output << "Status: #{task.status.upcase}"
          output << "Created: #{task.created_at}"
          output << ""

          case task.status
          when "pending"
            output << "Task is pending execution..."
          when "running"
            output << "Task is running... ⚙️"
          when "completed"
            output << "Output:"
            output << "--------"
            output << task.output.to_s
            output << ""
            output << "Cost: $#{task.cost_dollars}" if task.cost_dollars
          when "failed"
            output << "Error: #{task.error}"
          when "canceled"
            output << "Task was canceled"
            output << "Finished: #{task.finished_at}" if task.finished_at
          end

          if show_events && task.events && !task.events.empty?
            output << ""
            output << "Events:"
            output << "-------"
            task.events.each do |event|
              output << "- #{event}"
            end
          end

          output.join("\n")
        end

        def self.format_list_pretty(list)
          output = []
          output << "Research Tasks (#{list.data.length}):"
          output << ""

          if list.data.empty?
            output << "No tasks found."
          else
            # Simple table format
            output << "%-40s %-15s %s" % ["Task ID", "Status", "Created"]
            output << "-" * 70

            list.data.each do |task|
              task_id = task.research_id.to_s[0..38]
              status = task.status.upcase[0..14]
              created = task.created_at.to_s[0..19]
              output << "%-40s %-15s %s" % [task_id, status, created]
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

        def self.format_task_text(task, show_events: false)
          output = []
          output << "#{task.research_id} #{task.status.upcase} #{task.created_at}"
          if task.status == "completed"
            output << task.output.to_s
          elsif task.status == "failed"
            output << "Error: #{task.error}"
          end
          output.join("\n")
        end

        def self.format_list_text(list)
          output = list.data.map do |task|
            "#{task.research_id} #{task.status.upcase} #{task.created_at}"
          end
          output.join("\n")
        end
      end
    end
  end
end
