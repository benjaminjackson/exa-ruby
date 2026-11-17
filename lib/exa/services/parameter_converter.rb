# frozen_string_literal: true

module Exa
  module Services
    # Converts Ruby parameter names (snake_case) to API format (camelCase)
    # Handles both simple parameters and nested content parameters
    class ParameterConverter
      def self.convert(params)
        new.convert(params)
      end

      # Converts every key, at every depth, to camelCase without moving
      # content options under :contents. For endpoints such as /contents,
      # /answer and /context, where text and summary sit at the top level.
      def self.convert_keys(params)
        new.convert_keys(params)
      end

      def convert_keys(params)
        deep_convert(params)
      end

      def convert(params)
        consolidated = consolidate_content_params(params)
        converted = {}
        contents = {}

        consolidated.each do |key, value|
          converted_key = convert_key(key)
          if content_key?(key)
            contents[converted_key] = convert_value(converted_key, value)
          else
            converted[converted_key] = convert_value(converted_key, value)
          end
        end

        converted[:contents] = (converted[:contents] || {}).merge(contents) if contents.any?
        converted
      end

      private

      CONTENT_SUB_PARAMS = {
        text_max_characters: { parent: :text, key: :max_characters },
        include_html_tags: { parent: :text, key: :include_html_tags },
        text_verbosity: { parent: :text, key: :verbosity },
        text_link_style: { parent: :text, key: :link_style },
        text_include_sections: { parent: :text, key: :include_sections },
        text_exclude_sections: { parent: :text, key: :exclude_sections },
        summary_query: { parent: :summary, key: :query },
        summary_schema: { parent: :summary, key: :schema },
        context_max_characters: { parent: :context, key: :max_characters },
        highlights_max_characters: { parent: :highlights, key: :max_characters },
        highlights_num_sentences: { parent: :highlights, key: :num_sentences },
        highlights_per_url: { parent: :highlights, key: :highlights_per_url },
        highlights_query: { parent: :highlights, key: :query },
        highlights_verbosity: { parent: :highlights, key: :verbosity },
        highlights_dynamic: { parent: :highlights, key: :dynamic },
        image_links: { parent: :extras, key: :image_links },
        rich_image_links: { parent: :extras, key: :rich_image_links },
        links: { parent: :extras, key: :links }
      }.freeze

      def consolidate_content_params(params)
        result = {}
        params.each do |key, value|
          mapping = CONTENT_SUB_PARAMS[key]
          if mapping
            parent = mapping[:parent]
            result[parent] = {} if result[parent] == true || !result.key?(parent)
            result[parent] = {} unless result[parent].is_a?(Hash)
            result[parent][mapping[:key]] = value
          else
            result[key] = value
          end
        end
        result
      end

      # Values under these keys are user data (JSON schemas, free-form maps,
      # input records), so their keys are sent exactly as given.
      PROTECTED_KEYS = %w[outputSchema schema metadata data exclusion].freeze

      def convert_key(key)
        camelize(key)
      end

      # Turns foo_bar_baz into fooBarBaz and keeps the key's type (Symbol or
      # String). A key with no underscore, camelCase included, is left alone.
      def camelize(key)
        return key unless key.is_a?(Symbol) || key.is_a?(String)
        return key unless key.to_s.include?("_")

        camelized = key.to_s.gsub(/_([a-z\d])/) { Regexp.last_match(1).upcase }
        key.is_a?(Symbol) ? camelized.to_sym : camelized
      end

      def deep_convert(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested), result|
            converted_key = convert_key(key)
            result[converted_key] = convert_value(converted_key, nested)
          end
        when Array
          value.map { |element| deep_convert(element) }
        else
          value
        end
      end

      def convert_value(converted_key, value)
        return value if PROTECTED_KEYS.include?(converted_key.to_s)

        deep_convert(value)
      end

      def content_key?(key)
        %i[text summary context subpages subpage_target extras highlights livecrawl livecrawl_timeout max_age_hours
           snapshot_as_of crawled_before_date].include?(key)
      end
    end
  end
end
