# frozen_string_literal: true

module Exa
  module Services
    # Converts Ruby parameter names (snake_case) to API format (camelCase)
    # Handles both simple parameters and nested content parameters
    class ParameterConverter
      def self.convert(params)
        new.convert(params)
      end

      # Folds flat content keys under their parent at the top level, with no
      # :contents wrapper, then converts every key to camelCase. This is the
      # shape /contents takes: text, summary and highlights sit at the top.
      def self.convert_contents(params)
        new.convert_contents(params)
      end

      # Converts every key, at every depth, to camelCase without folding or
      # moving any key. For /answer and /context, which take no content
      # sub-options.
      def self.convert_keys(params)
        new.convert_keys(params)
      end

      def convert_keys(params)
        deep_convert(params)
      end

      # Instance form of ParameterConverter.convert_contents.
      def convert_contents(params)
        deep_convert(consolidate_content_params(params))
      end

      # Folds flat content keys under their parent, then moves content
      # options under :contents. A caller's own contents hash, given under
      # :contents or "contents", is merged with the folded keys into one
      # :contents key; flat keys win on a real conflict. Only the top level of
      # the params is normalised: flat keys inside the caller's contents hash
      # are not folded, and a String key inside it is not matched with the
      # same Symbol key.
      def convert(params)
        consolidated = consolidate_content_params(params)
        converted = {}
        contents = {}

        consolidated.each do |key, value|
          converted_key = convert_key(key)
          if key.to_s == "contents"
            converted[:contents] = merge_option(converted[:contents], deep_convert(value))
          elsif content_key?(key)
            contents[converted_key] = convert_value(converted_key, value)
          else
            converted[converted_key] = convert_value(converted_key, value)
          end
        end

        converted[:contents] = merge_option(converted[:contents], contents) if contents.any?
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
            result[parent] = merge_option(result[parent], { mapping[:key] => value })
          else
            result[key] = merge_option(result[key], value)
          end
        end
        result
      end

      # Merges an incoming option value into an existing one. Two Hashes
      # merge key by key; a Hash beats a bare true, which only turns the
      # option on, so text: true and text_max_characters: 500 give the same
      # result in either order. Otherwise the incoming value wins, so with
      # false or nil the key given last wins. A value under a
      # protected key (a user's schema) is replaced, never merged.
      def merge_option(existing, incoming)
        return existing if existing.is_a?(Hash) && incoming == true
        return incoming unless existing.is_a?(Hash) && incoming.is_a?(Hash)

        existing.merge(incoming) do |key, existing_value, incoming_value|
          next incoming_value if PROTECTED_KEYS.include?(camelize(key).to_s)

          merge_option(existing_value, incoming_value)
        end
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
