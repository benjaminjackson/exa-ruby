# frozen_string_literal: true

require "json"

module Exa
  module CLI
    class Base
      # Resolve API key from flag or environment variable
      # Flag takes precedence over environment variable
      def self.resolve_api_key(flag_value)
        return flag_value if flag_value && !flag_value.empty?

        env_key = ENV["EXA_API_KEY"]
        return env_key if env_key && !env_key.empty?

        raise Exa::ConfigurationError,
              "Missing API key. Set EXA_API_KEY environment variable or use --api-key flag"
      end

      # Resolve and validate output format
      # Valid formats: json, pretty, text, toon
      # Defaults to json
      def self.resolve_output_format(flag_value)
        format = (flag_value || "json").downcase
        valid_formats = %w[json pretty text toon]

        return format if valid_formats.include?(format)

        raise Exa::ConfigurationError,
              "Invalid output format: #{format}. Valid formats: #{valid_formats.join(', ')}"
      end

      # Build a client instance with the given API key
      def self.build_client(api_key, **options)
        Exa::Client.new(api_key: api_key, **options)
      end

      # Format output data based on format type
      def self.format_output(data, format)
        case format
        when "json"
          JSON.pretty_generate(data.is_a?(Hash) ? data : { result: data })
        when "pretty"
          data.inspect
        when "text"
          data.to_s
        else
          data.to_s
        end
      end

      # Encode data as TOON format
      def self.encode_as_toon(data)
        require "toon" unless defined?(Toon)
        Toon.encode(data)
      end

      # Return the value given after a flag. When the flag came last with no
      # value, print one error line and exit, so the command does not crash
      # later with a NoMethodError on nil. Exits instead of raising because
      # many commands parse their options outside their rescue block.
      def self.option_value(flag, value)
        fail_with("#{flag} needs a value") if value.nil?

        value
      end

      # Return the value of a free-text option such as --summary-query. Like
      # option_value, but also fails when the value starts with two dashes:
      # that is the next flag, so the user left this option's value out.
      def self.text_value(flag, value)
        option_value(flag, value)
        fail_with("#{flag} needs a value (got the flag #{value})") if value.start_with?("--")

        value
      end

      # Parse a base-10 integer option. "abc", "10abc", "1.5" and "0x10" all
      # fail with one error line instead of silently becoming a number.
      def self.parse_integer(flag, value)
        Integer(option_value(flag, value), 10)
      rescue ArgumentError
        fail_with("#{flag} must be a number (got #{value.inspect})")
      end

      # Parse a JSON option. A value that starts with @ names a file to read
      # the JSON from. Hash keys stay strings unless symbolize_names is true.
      def self.parse_json_or_file(flag, value, symbolize_names: false)
        text = option_value(flag, value)
        text = File.read(text[1..]) if text.start_with?("@")
        JSON.parse(text, symbolize_names: symbolize_names)
      rescue JSON::ParserError => e
        fail_with("#{flag} is not valid JSON: #{e.message.lines.first.strip}")
      rescue SystemCallError => e
        fail_with("#{flag} file could not be read: #{e.message}")
      end

      # Print one error line to stderr and exit with status 1.
      def self.fail_with(message)
        warn "Error: #{message}"
        exit 1
      end
      private_class_method :fail_with
    end
  end
end
