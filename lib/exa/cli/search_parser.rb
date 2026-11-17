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

      # Every flag exa-ai search accepts. Public API: wrappers read it here or
      # through `exa-ai search --flags-json`, and the parser rejects any "--"
      # argument that is not in it. api_field is the request body path the
      # flag sets (nil when it sets none, an Array when it sets several), and
      # replacement is what to type instead of a deprecated flag.
      FLAGS = [
        { flag: "--num-results", api_field: "numResults", deprecated: false, replacement: nil },
        { flag: "--type", api_field: "type", deprecated: false, replacement: nil },
        { flag: "--category", api_field: "category", deprecated: false, replacement: nil },
        { flag: "--include-domains", api_field: "includeDomains", deprecated: false, replacement: nil },
        { flag: "--exclude-domains", api_field: "excludeDomains", deprecated: false, replacement: nil },
        { flag: "--start-published-date", api_field: "startPublishedDate", deprecated: false, replacement: nil },
        { flag: "--end-published-date", api_field: "endPublishedDate", deprecated: false, replacement: nil },
        { flag: "--start-crawl-date", api_field: "startCrawlDate", deprecated: true, replacement: nil },
        { flag: "--end-crawl-date", api_field: "endCrawlDate", deprecated: true, replacement: nil },
        { flag: "--include-text", api_field: "includeText", deprecated: true, replacement: nil },
        { flag: "--exclude-text", api_field: "excludeText", deprecated: true, replacement: nil },
        { flag: "--text", api_field: "contents.text", deprecated: false, replacement: nil },
        { flag: "--text-max-characters", api_field: "contents.text.maxCharacters", deprecated: false, replacement: nil },
        { flag: "--text-verbosity", api_field: "contents.text.verbosity", deprecated: false, replacement: nil },
        { flag: "--include-html-tags", api_field: "contents.text.includeHtmlTags", deprecated: false, replacement: nil },
        { flag: "--summary", api_field: "contents.summary", deprecated: false, replacement: nil },
        { flag: "--summary-query", api_field: "contents.summary.query", deprecated: false, replacement: nil },
        { flag: "--summary-schema", api_field: "contents.summary.schema", deprecated: false, replacement: nil },
        { flag: "--context", api_field: "contents.context", deprecated: true, replacement: "--highlights or --text" },
        { flag: "--context-max-characters", api_field: "contents.context.maxCharacters", deprecated: true,
          replacement: nil },
        { flag: "--subpages", api_field: "contents.subpages", deprecated: true,
          replacement: "exa-ai get-contents --subpages" },
        { flag: "--subpage-target", api_field: "contents.subpageTarget", deprecated: true,
          replacement: "exa-ai get-contents --subpage-target" },
        { flag: "--links", api_field: "contents.extras.links", deprecated: false, replacement: nil },
        { flag: "--image-links", api_field: "contents.extras.imageLinks", deprecated: false, replacement: nil },
        { flag: "--highlights", api_field: "contents.highlights", deprecated: false, replacement: nil },
        { flag: "--highlights-max-characters", api_field: "contents.highlights.maxCharacters", deprecated: false,
          replacement: nil },
        { flag: "--highlights-num-sentences", api_field: "contents.highlights.numSentences", deprecated: true,
          replacement: "--highlights-max-characters" },
        { flag: "--highlights-per-url", api_field: "contents.highlights.highlightsPerUrl", deprecated: true,
          replacement: nil },
        { flag: "--highlights-query", api_field: "contents.highlights.query", deprecated: false, replacement: nil },
        { flag: "--livecrawl", api_field: ["contents.maxAgeHours", "contents.livecrawlTimeout"].freeze,
          deprecated: true, replacement: "--max-age-hours 0 --livecrawl-timeout 5000" },
        { flag: "--livecrawl-timeout", api_field: "contents.livecrawlTimeout", deprecated: false, replacement: nil },
        { flag: "--max-age-hours", api_field: "contents.maxAgeHours", deprecated: false, replacement: nil },
        { flag: "--snapshot-as-of", api_field: "contents.snapshotAsOf", deprecated: false, replacement: nil },
        { flag: "--additional-queries", api_field: "additionalQueries", deprecated: false, replacement: nil },
        { flag: "--output-schema", api_field: "outputSchema", deprecated: false, replacement: nil },
        { flag: "--user-location", api_field: "userLocation", deprecated: false, replacement: nil },
        { flag: "--objective", api_field: "objective", deprecated: false, replacement: nil },
        { flag: "--user-identifier", api_field: "userIdentifier", deprecated: false, replacement: nil },
        { flag: "--compliance", api_field: "compliance", deprecated: false, replacement: nil },
        { flag: "--system-prompt", api_field: "systemPrompt", deprecated: false, replacement: nil },
        { flag: "--moderation", api_field: "moderation", deprecated: false, replacement: nil },
        { flag: "--api-key", api_field: nil, deprecated: false, replacement: nil },
        { flag: "--output-format", api_field: nil, deprecated: false, replacement: nil },
        { flag: "--print-request", api_field: nil, deprecated: false, replacement: nil },
        { flag: "--flags-json", api_field: nil, deprecated: false, replacement: nil },
        { flag: "--help", api_field: nil, deprecated: false, replacement: nil }
      ].map(&:freeze).freeze

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
          Exa::CLI::Base.reject_unknown_option(arg) if arg.start_with?("--") && FLAGS.none? { |entry| entry[:flag] == arg }

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
