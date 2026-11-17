require "json"
require_relative "parameter_converter"
require_relative "../resources/agent_run"

# ponytail: copied AnswerStream's SSE parser rather than extracting a shared module — agent frames add event:/id: lines and the two may diverge. Extract only if a third SSE consumer appears.

module Exa
  module Services
    class AgentRunStream
      TERMINAL_EVENTS = %w[agent_run.completed agent_run.failed agent_run.cancelled].freeze

      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      # Parses one SSE frame (the lines between two blank lines) and returns
      # [event_type, data, event_id], or nil when the frame has no data line or
      # its data is not valid JSON. Reads "id:", "event:" and "data:" with or
      # without the one space after the colon, skips comment lines that start
      # with ":", and joins several data lines with "\n" as the SSE format says.
      def self.parse_frame(frame)
        event_type = nil
        event_id = nil
        data_lines = []

        frame.split("\n").each do |line|
          # A stream that ends between "\r" and "\n" leaves a "\r" behind.
          line = line.chomp("\r")
          next if line.start_with?(":")

          field, value = line.split(":", 2)
          next if value.nil?

          # The SSE format allows one optional space after the colon.
          value = value.delete_prefix(" ")
          case field
          when "event" then event_type = value
          when "id"    then event_id = value
          when "data"  then data_lines << value
          end
        end

        return nil if data_lines.empty?

        [event_type, JSON.parse(data_lines.join("\n")), event_id]
      rescue JSON::ParserError
        nil
      end

      # Streams SSE frames to the block as (event_type, data, event_id). A
      # block that takes two arguments gets (event_type, data). Returns the
      # final AgentRun built from the terminal event's payload (completed/
      # failed/cancelled), or nil if the stream ended before a terminal event
      # arrived.
      def call(&block)
        raise ArgumentError, "block required for streaming" unless block_given?

        @buffer = ""
        @final_payload = nil

        # Capture the terminal payload as it streams, then forward to the caller.
        interceptor = proc do |event_type, data, event_id|
          @final_payload = data if TERMINAL_EVENTS.include?(event_type)
          block.call(event_type, data, event_id)
        end

        body = ParameterConverter.convert(@params)

        @connection.post("/agent/runs", body) do |req|
          req.headers["Accept"] = "text/event-stream"
          req.options.on_data = proc do |chunk, _size, env|
            next env[:error_body] = "#{env[:error_body]}#{chunk}" if env&.status.to_i >= 400

            # Normalise CRLF line endings. A "\r" at the end of one chunk joins
            # its "\n" here once the next chunk arrives.
            @buffer = (@buffer + chunk).gsub("\r\n", "\n")
            process_sse_buffer(&interceptor)
          end
        end

        unless @buffer.empty?
          event = self.class.parse_frame(@buffer)
          interceptor.call(*event) if event
        end

        @final_payload && Resources::AgentRun.from_response(@final_payload)
      end

      private

      # Yields each complete frame in the buffer and keeps the incomplete
      # tail for the next chunk.
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
          event = self.class.parse_frame(frame)
          yield(*event) if event
        end
      end
    end
  end
end
