# frozen_string_literal: true

module Exa
  module CLI
    class SearchParser
      VALID_SEARCH_TYPES = ["fast", "deep", "keyword", "auto"].freeze
      VALID_CATEGORIES = [
        "company", "research paper", "news", "pdf", "github",
        "tweet", "personal site", "financial report", "people"
      ].freeze

      def self.parse(argv)
        new(argv).parse
      end

      def initialize(argv)
        @argv = argv
        @args = {
          output_format: "json",
          api_key: nil
        }
      end

      def parse
        parse_arguments
        validate_query
        @args
      end

      private

      def parse_arguments
        query_parts = []
        i = 0

        while i < @argv.length
          arg = @argv[i]
          case arg
          when "--num-results"
            @args[:num_results] = @argv[i + 1].to_i
            i += 2
          when "--type"
            search_type = @argv[i + 1]
            validate_search_type(search_type)
            @args[:type] = search_type
            i += 2
          when "--category"
            category = @argv[i + 1]
            validate_category(category)
            @args[:category] = category
            i += 2
          when "--include-domains"
            @args[:include_domains] = @argv[i + 1].split(",").map(&:strip)
            i += 2
          when "--exclude-domains"
            @args[:exclude_domains] = @argv[i + 1].split(",").map(&:strip)
            i += 2
          when "--api-key"
            @args[:api_key] = @argv[i + 1]
            i += 2
          when "--output-format"
            @args[:output_format] = @argv[i + 1]
            i += 2
          when "--start-published-date"
            @args[:start_published_date] = @argv[i + 1]
            i += 2
          when "--end-published-date"
            @args[:end_published_date] = @argv[i + 1]
            i += 2
          when "--start-crawl-date"
            @args[:start_crawl_date] = @argv[i + 1]
            i += 2
          when "--end-crawl-date"
            @args[:end_crawl_date] = @argv[i + 1]
            i += 2
          when "--include-text"
            @args[:include_text] ||= []
            @args[:include_text] << @argv[i + 1]
            i += 2
          when "--exclude-text"
            @args[:exclude_text] ||= []
            @args[:exclude_text] << @argv[i + 1]
            i += 2
          when "--text"
            @args[:text] = true
            i += 1
          when "--text-max-characters"
            @args[:text_max_characters] = @argv[i + 1].to_i
            i += 2
          when "--include-html-tags"
            @args[:include_html_tags] = true
            i += 1
          when "--summary"
            @args[:summary] = true
            i += 1
          when "--summary-query"
            @args[:summary_query] = @argv[i + 1]
            i += 2
          when "--summary-schema"
            schema_arg = @argv[i + 1]
            @args[:summary_schema] = if schema_arg.start_with?("@")
                                      JSON.parse(File.read(schema_arg[1..]))
                                    else
                                      JSON.parse(schema_arg)
                                    end
            i += 2
          when "--context"
            @args[:context] = true
            i += 1
          when "--context-max-characters"
            @args[:context_max_characters] = @argv[i + 1].to_i
            i += 2
          when "--subpages"
            @args[:subpages] = @argv[i + 1].to_i
            i += 2
          when "--subpage-target"
            @args[:subpage_target] ||= []
            @args[:subpage_target] << @argv[i + 1]
            i += 2
          when "--links"
            @args[:links] = @argv[i + 1].to_i
            i += 2
          when "--image-links"
            @args[:image_links] = @argv[i + 1].to_i
            i += 2
          else
            query_parts << arg
            i += 1
          end
        end

        @args[:query] = query_parts.join(" ")
      end

      def validate_query
        raise ArgumentError, "Query is required" if @args[:query].nil? || @args[:query].empty?
      end

      def validate_search_type(search_type)
        return if VALID_SEARCH_TYPES.include?(search_type)

        raise ArgumentError, "Search type must be one of: #{VALID_SEARCH_TYPES.join(', ')}"
      end

      def validate_category(category)
        return if VALID_CATEGORIES.include?(category)

        raise ArgumentError, "Category must be one of: #{VALID_CATEGORIES.map { |c| "\"#{c}\"" }.join(', ')}"
      end
    end
  end
end
