require "json"

module Exa
  module Services
    class AnswerStream
      def initialize(connection, **params)
        @connection = connection
        @params = params.merge(stream: true)
      end

      def call(&block)
        raise ArgumentError, "block required for streaming" unless block_given?

        # Use instance variable to track buffer across on_data callbacks
        @buffer = ""

        # Configure the request to stream chunks via on_data callback
        @connection.post("/answer", @params) do |req|
          req.options.on_data = proc do |chunk|
            # Add chunk to buffer and process complete SSE events
            @buffer += chunk
            process_sse_buffer(&block)
          end
        end

        # Process any remaining data in buffer after stream ends
        process_remaining_buffer(&block) if @buffer.length.positive?
      end

      private

      def process_sse_buffer
        # Extract and process complete SSE events (separated by \n\n)
        # If buffer ends with \n\n, all parts are complete.
        # Otherwise, keep the last part in buffer for next chunk.

        return if @buffer.empty?

        parts = @buffer.split("\n\n")

        # When split by a delimiter, if the string ends with the delimiter,
        # split doesn't add a trailing empty string. So we need to track
        # whether the buffer ended with \n\n to know if the last part is incomplete.
        if @buffer.end_with?("\n\n")
          # All parts are complete, clear buffer
          complete_parts = parts
          @buffer = ""
        else
          # Last part is incomplete, keep it for next chunk
          complete_parts = parts[0...-1]
          @buffer = parts.last || ""
        end

        # Process all complete events
        complete_parts.each do |event|
          next if event.empty?

          lines = event.split("\n")
          lines.each do |line|
            if line.start_with?("data: ")
              json_str = line.sub(/^data: /, "").strip
              begin
                data = JSON.parse(json_str)
                yield(data)
              rescue JSON::ParserError
                # Skip lines that aren't valid JSON
              end
            end
          end
        end
      end

      def process_remaining_buffer
        # Process any remaining incomplete buffer
        lines = @buffer.split("\n")
        lines.each do |line|
          if line.start_with?("data: ")
            json_str = line.sub(/^data: /, "").strip
            begin
              data = JSON.parse(json_str)
              yield(data)
            rescue JSON::ParserError
              # Skip lines that aren't valid JSON
            end
          end
        end
      end
    end
  end
end
