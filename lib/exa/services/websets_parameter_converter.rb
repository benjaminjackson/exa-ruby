# frozen_string_literal: true

module Exa
  module Services
    # Converts Ruby parameter names (snake_case) to API format (camelCase) for Websets API
    class WebsetsParameterConverter
      def self.convert(params)
        new.convert(params)
      end

      def convert(params)
        converted = {}

        params.each do |key, value|
          converted_key = convert_key(key)
          converted_value = convert_value(key, value)
          converted[converted_key] = converted_value
        end

        converted
      end

      private

      def convert_key(key)
        case key
        when :external_id then :externalId
        else
          key
        end
      end

      def convert_value(key, value)
        # Recursively convert nested hashes
        if value.is_a?(Hash)
          convert(value)
        elsif value.is_a?(Array)
          value.map { |item| item.is_a?(Hash) ? convert(item) : item }
        else
          value
        end
      end
    end
  end
end
