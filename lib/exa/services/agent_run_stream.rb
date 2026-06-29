require "json"
require_relative "parameter_converter"

# ponytail: copied AnswerStream's SSE parser rather than extracting a shared module — agent frames add event:/id: lines and the two may diverge. Extract only if a third SSE consumer appears.

module Exa
  module Services
    class AgentRunStream
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call(&block)
        raise ArgumentError, "block required for streaming" unless block_given?

        @buffer = ""

        body = ParameterConverter.convert(@params)

        @connection.post("/agent/runs", body) do |req|
          req.headers["Accept"] = "text/event-stream"
          req.options.on_data = proc do |chunk|
            @buffer += chunk
            process_sse_buffer(&block)
          end
        end

        process_remaining_buffer(&block) if @buffer.length.positive?
      end

      private

      def process_sse_buffer
        return if @buffer.empty?

        parts = @buffer.split("\n\n")

        if @buffer.end_with?("\n\n")
          complete_parts = parts
          @buffer = ""
        else
          complete_parts = parts[0...-1]
          @buffer = parts.last || ""
        end

        complete_parts.each do |frame|
          next if frame.empty?

          event_type = nil
          data_json = nil

          frame.split("\n").each do |line|
            if line.start_with?("event: ")
              event_type = line.sub(/^event: /, "").strip
            elsif line.start_with?("data: ")
              data_json = line.sub(/^data: /, "").strip
            end
          end

          next if data_json.nil?

          begin
            data = JSON.parse(data_json)
            yield(event_type, data)
          rescue JSON::ParserError
            # Skip lines that aren't valid JSON
          end
        end
      end

      def process_remaining_buffer
        event_type = nil
        data_json = nil

        @buffer.split("\n").each do |line|
          if line.start_with?("event: ")
            event_type = line.sub(/^event: /, "").strip
          elsif line.start_with?("data: ")
            data_json = line.sub(/^data: /, "").strip
          end
        end

        return if data_json.nil?

        begin
          data = JSON.parse(data_json)
          yield(event_type, data)
        rescue JSON::ParserError
          # Skip lines that aren't valid JSON
        end
      end
    end
  end
end
