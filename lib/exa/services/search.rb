# frozen_string_literal: true

module Exa
  module Services
    class Search
      def initialize(connection, **params)
        @connection = connection
        @params = params
      end

      def call
        response = @connection.post("/search", convert_params(@params))
        body = response.body

        Resources::SearchResult.new(
          results: body["results"],
          request_id: body["requestId"],
          resolved_search_type: body["resolvedSearchType"],
          search_type: body["searchType"],
          context: body["context"],
          cost_dollars: body["costDollars"]
        )
      end

      private

      def convert_params(params)
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

      def convert_key(key)
        case key
        when :start_published_date then :startPublishedDate
        when :end_published_date then :endPublishedDate
        when :start_crawl_date then :startCrawlDate
        when :end_crawl_date then :endCrawlDate
        when :include_text then :includeText
        when :exclude_text then :excludeText
        else
          key
        end
      end

      def content_key?(key)
        %i[text summary context subpages subpage_target extras].include?(key)
      end

      def convert_content_key(key)
        case key
        when :subpage_target then :subpageTarget
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
          include_html_tags: :includeHtmlTags
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
    end
  end
end
