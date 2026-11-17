require "json"

require_relative "parameter_converter"
require_relative "agent_run_stream"

module Exa
  module Services
    class AnswerStream
      def initialize(connection, **params)
        @connection = connection
        @params = ParameterConverter.convert_keys(params.merge(stream: true))
      end

      def call(&block)
        raise ArgumentError, "block required for streaming" unless block_given?

        # Use instance variable to track buffer across on_data callbacks
        @buffer = ""

        # Configure the request to stream chunks via on_data callback
        @connection.post(path, @params) do |req|
          req.headers.update(headers)
          req.options.on_data = proc do |chunk, _size, env|
            next env[:error_body] = "#{env[:error_body]}#{chunk}" if env&.status.to_i >= 400

            # Normalise CRLF line endings. A "\r" at the end of one chunk joins
            # its "\n" here once the next chunk arrives.
            @buffer = (@buffer + chunk).gsub("\r\n", "\n")
            process_sse_buffer(&block)
          end
        end

        # Process the last frame when the stream ends without a blank line
        process_frame(@buffer, &block)
      end

      private

      # The endpoint this stream posts to. SearchStream overrides it.
      def path
        "/answer"
      end

      # Extra request headers for this stream. SearchStream overrides it.
      def headers
        {}
      end

      # Raises Exa::Error when a chunk is an error event.
      # /search sends {"type":"error","error":{"message":...}}; /answer sends
      # {"tag":"ERROR","payload":{"error":{"code":...,"message":...}}}.
      # A chunk that is not a JSON object is never an error event. When the
      # message is missing, the chunk itself becomes the message.
      def raise_if_error_chunk(data)
        return unless data.is_a?(Hash)

        message = if data["type"] == "error"
                    data.dig("error", "message")
                  elsif data["tag"] == "ERROR"
                    data.dig("payload", "error", "message")
                  else
                    return
                  end
        raise Exa::Error, message || JSON.generate(data)
      end

      # Yields each complete frame in the buffer and keeps the incomplete
      # tail for the next chunk.
      def process_sse_buffer(&block)
        return if @buffer.empty?

        parts = @buffer.split("\n\n")

        if @buffer.end_with?("\n\n")
          complete_parts = parts
          @buffer = ""
        else
          complete_parts = parts[0...-1]
          @buffer = parts.last || ""
        end

        complete_parts.each { |frame| process_frame(frame, &block) }
      end

      # Yields the data of each data: line in one SSE frame. Each line is its
      # own JSON value, so a bad line does not drop a good one next to it.
      # Lines that are not data lines, and data that is not JSON such as
      # [DONE], are skipped.
      def process_frame(frame)
        frame.split("\n").each do |line|
          event = AgentRunStream.parse_frame(line)
          next unless event

          data = event[1]
          raise_if_error_chunk(data)
          yield(data)
        end
      end
    end
  end
end
