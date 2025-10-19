# frozen_string_literal: true

module Exa
  module CLI
    class Polling
      class TimeoutError < StandardError; end

      # Poll a block until it returns done: true
      # Implements exponential backoff with jitter
      #
      # Options:
      #   max_duration: Maximum time to poll (default: 300 seconds / 5 minutes)
      #   initial_delay: Initial delay in seconds (default: 1)
      #   max_delay: Maximum delay between polls (default: 30)
      #
      # Block should return a hash:
      #   { done: boolean, result: any, status: string }
      #
      # Returns the result value when done is true
      def self.poll(max_duration: 300, initial_delay: 1, max_delay: 30)
        start_time = Time.now
        current_delay = initial_delay
        attempt = 0

        loop do
          response = yield
          return response[:result] if response[:done]

          elapsed_time = Time.now - start_time
          if elapsed_time > max_duration
            raise TimeoutError,
                  "Polling timed out after #{elapsed_time.round(2)} seconds"
          end

          # Sleep before next attempt
          sleep [current_delay, max_delay].min

          # Exponential backoff: multiply by 2 for next iteration
          current_delay *= 2

          attempt += 1
        end
      end
    end
  end
end
