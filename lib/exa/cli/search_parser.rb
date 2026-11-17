# frozen_string_literal: true

require_relative "contents_flags"

module Exa
  module CLI
    class SearchParser
      VALID_SEARCH_TYPES = ["auto", "lite", "deep-lite", "neural", "fast", "deep", "deep-reasoning", "instant"].freeze
      VALID_TEXT_VERBOSITY = ContentsFlags::VALID_TEXT_VERBOSITY
      VALID_COMPLIANCE = ["hipaa"].freeze
      VALID_CATEGORIES = [
        "company", "publication", "news",
        "personal site", "people", "financial report"
      ].freeze

      def self.parse(argv)
        new(argv).parse
      end

      # A country code stays a string. An argument that starts with "{" is
      # parsed as a JSON object, and one that starts with "@" is read as a
      # JSON file, the way --output-schema works. A missing value gives nil,
      # so the flag is skipped. Bad JSON or an unreadable file exits 1 with
      # one error line that names --user-location.
      def self.parse_user_location(value)
        return nil if value.nil?
        return Base.parse_json_or_file("--user-location", value) if value.start_with?("@", "{")

        value
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
          next_index = ContentsFlags.parse(@argv, i, @args)
          if next_index
            i = next_index
            next
          end

          case arg
          when "--num-results"
            @args[:num_results] = Exa::CLI::Base.parse_integer("--num-results", @argv[i + 1])
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
            @args[:include_domains] = Exa::CLI::Base.option_value("--include-domains", @argv[i + 1]).split(",").map(&:strip)
            i += 2
          when "--exclude-domains"
            @args[:exclude_domains] = Exa::CLI::Base.option_value("--exclude-domains", @argv[i + 1]).split(",").map(&:strip)
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
          when "--additional-queries"
            @args[:additional_queries] ||= []
            @args[:additional_queries] << @argv[i + 1]
            i += 2
          when "--output-schema"
            @args[:output_schema] = Exa::CLI::Base.parse_json_or_file("--output-schema", @argv[i + 1])
            i += 2
          when "--user-location"
            @args[:user_location] = self.class.parse_user_location(@argv[i + 1])
            i += 2
          when "--objective"
            @args[:objective] = @argv[i + 1]
            i += 2
          when "--user-identifier"
            @args[:user_identifier] = @argv[i + 1]
            i += 2
          when "--compliance"
            compliance = @argv[i + 1]
            validate_compliance(compliance)
            @args[:compliance] = compliance
            i += 2
          when "--system-prompt"
            @args[:system_prompt] = @argv[i + 1]
            i += 2
          when "--moderation"
            @args[:moderation] = true
            i += 1
          when "--print-request"
            @args[:print_request] = true
            i += 1
          else
            Exa::CLI::Base.reject_unknown_option(arg) if arg.start_with?("--")

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

      # Raises ArgumentError unless compliance is a value the API accepts.
      def validate_compliance(compliance)
        return if VALID_COMPLIANCE.include?(compliance)

        raise ArgumentError, "Compliance must be one of: #{VALID_COMPLIANCE.join(', ')}"
      end
    end
  end
end
