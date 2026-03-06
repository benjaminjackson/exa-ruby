# frozen_string_literal: true

module Exa
  module Services
    # Converts Ruby parameter names (snake_case) to API format (camelCase)
    # Handles both simple parameters and nested content parameters
    class ParameterConverter
      def self.convert(params)
        new.convert(params)
      end

      def convert(params)
        converted = {}
        contents = {}

        params.each do |key, value|
          if content_key?(key)
            contents[convert_content_key(key)] = convert_content_value(key, value)
          else
            converted[convert_key(key)] = value
          end
        end

        converted[:contents] = contents if contents.any?
        converted
      end

      private

      def convert_key(key)
        case key
        when :start_published_date then :startPublishedDate
        when :end_published_date then :endPublishedDate
        when :start_crawl_date then :startCrawlDate
        when :end_crawl_date then :endCrawlDate
        when :include_text then :includeText
        when :exclude_text then :excludeText
        when :external_id then :externalId
        when :additional_queries then :additionalQueries
        when :output_schema then :outputSchema
        when :user_location then :userLocation
        else
          key
        end
      end

      def content_key?(key)
        %i[text summary context subpages subpage_target extras highlights livecrawl livecrawl_timeout max_age_hours].include?(key)
      end

      def convert_content_key(key)
        case key
        when :subpage_target then :subpageTarget
        when :livecrawl_timeout then :livecrawlTimeout
        when :max_age_hours then :maxAgeHours
        else
          key
        end
      end

      def convert_content_value(key, value)
        case key
        when :text
          if value.is_a?(Hash)
            convert_hash_value(value, text_hash_mappings)
          else
            value
          end
        when :summary
          if value.is_a?(Hash)
            convert_hash_value(value, summary_hash_mappings)
          else
            value
          end
        when :context
          if value.is_a?(Hash)
            convert_hash_value(value, context_hash_mappings)
          else
            value
          end
        when :extras
          if value.is_a?(Hash)
            convert_hash_value(value, extras_hash_mappings)
          else
            value
          end
        when :highlights
          if value.is_a?(Hash)
            convert_hash_value(value, highlights_hash_mappings)
          else
            value
          end
        else
          value
        end
      end

      def convert_hash_value(hash, mappings)
        converted = {}
        hash.each do |k, v|
          converted_key = mappings[k] || k
          converted[converted_key] = v
        end
        converted
      end

      def text_hash_mappings
        {
          max_characters: :maxCharacters,
          include_html_tags: :includeHtmlTags,
          include_sections: :includeSections,
          exclude_sections: :excludeSections
        }
      end

      def summary_hash_mappings
        {
          query: :query,
          schema: :schema
        }
      end

      def context_hash_mappings
        {
          max_characters: :maxCharacters
        }
      end

      def extras_hash_mappings
        {
          image_links: :imageLinks
        }
      end

      def highlights_hash_mappings
        {
          max_characters: :maxCharacters,
          num_sentences: :numSentences,
          highlights_per_url: :highlightsPerUrl,
          query: :query
        }
      end
    end
  end
end
