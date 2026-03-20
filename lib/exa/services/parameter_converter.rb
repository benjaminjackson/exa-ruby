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
        consolidated = consolidate_content_params(params)
        converted = {}
        contents = {}

        consolidated.each do |key, value|
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

      CONTENT_SUB_PARAMS = {
        text_max_characters: { parent: :text, key: :max_characters },
        include_html_tags: { parent: :text, key: :include_html_tags },
        text_verbosity: { parent: :text, key: :verbosity },
        summary_query: { parent: :summary, key: :query },
        summary_schema: { parent: :summary, key: :schema },
        context_max_characters: { parent: :context, key: :max_characters },
        highlights_max_characters: { parent: :highlights, key: :max_characters },
        highlights_num_sentences: { parent: :highlights, key: :num_sentences },
        highlights_per_url: { parent: :highlights, key: :highlights_per_url },
        highlights_query: { parent: :highlights, key: :query },
        image_links: { parent: :extras, key: :image_links },
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
        when :num_results then :numResults
        when :include_domains then :includeDomains
        when :exclude_domains then :excludeDomains
        when :system_prompt then :systemPrompt
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
          exclude_sections: :excludeSections,
          verbosity: :verbosity
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
