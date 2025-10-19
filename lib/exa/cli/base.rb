# frozen_string_literal: true

module Exa
  module CLI
    class Base
      # Resolve API key from flag or environment variable
      # Flag takes precedence over environment variable
      def self.resolve_api_key(flag_value)
        return flag_value if flag_value && !flag_value.empty?

        env_key = ENV["EXA_API_KEY"]
        return env_key if env_key && !env_key.empty?

        raise ConfigurationError,
              "Missing API key. Set EXA_API_KEY environment variable or use --api-key flag"
      end

      # Resolve and validate output format
      # Valid formats: json, pretty, text
      # Defaults to json
      def self.resolve_output_format(flag_value)
        format = (flag_value || "json").downcase
        valid_formats = %w[json pretty text]

        return format if valid_formats.include?(format)

        raise ConfigurationError,
              "Invalid output format: #{format}. Valid formats: #{valid_formats.join(', ')}"
      end

      # Build a client instance with the given API key
      def self.build_client(api_key, **options)
        Client.new(api_key: api_key, **options)
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
    end
  end
end
