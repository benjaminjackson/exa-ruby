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
      # replacement is what to type instead of a deprecated flag. reason says
      # why a deprecated flag with no replacement is deprecated (nil for every
      # other flag). --help and
      # --flags-json are in the list, but exe/exa-ai-search handles them before
      # it calls the parser, which has no branch for them.
      FLAGS = [
        { flag: "--num-results", api_field: "numResults", deprecated: false, replacement: nil, reason: nil },
        { flag: "--type", api_field: "type", deprecated: false, replacement: nil, reason: nil },
        { flag: "--category", api_field: "category", deprecated: false, replacement: nil, reason: nil },
        { flag: "--include-domains", api_field: "includeDomains", deprecated: false, replacement: nil, reason: nil },
        { flag: "--exclude-domains", api_field: "excludeDomains", deprecated: false, replacement: nil, reason: nil },
        { flag: "--start-published-date", api_field: "startPublishedDate", deprecated: false, replacement: nil, reason: nil },
        { flag: "--end-published-date", api_field: "endPublishedDate", deprecated: false, replacement: nil, reason: nil },
        { flag: "--start-crawl-date", api_field: "startCrawlDate", deprecated: true, replacement: nil,
          reason: "the API ignores it and returns a warning" },
        { flag: "--end-crawl-date", api_field: "endCrawlDate", deprecated: true, replacement: nil,
          reason: "the API ignores it and returns a warning" },
        { flag: "--include-text", api_field: "includeText", deprecated: true, replacement: nil,
          reason: "it still works, but the match is approximate (word-level, not exact phrase)" },
        { flag: "--exclude-text", api_field: "excludeText", deprecated: true, replacement: nil,
          reason: "it still works, but the match is approximate (word-level, not exact phrase)" },
        { flag: "--text", api_field: "contents.text", deprecated: false, replacement: nil, reason: nil },
        { flag: "--text-max-characters", api_field: "contents.text.maxCharacters", deprecated: false, replacement: nil, reason: nil },
        { flag: "--text-verbosity", api_field: "contents.text.verbosity", deprecated: false, replacement: nil, reason: nil },
        { flag: "--include-html-tags", api_field: "contents.text.includeHtmlTags", deprecated: false, replacement: nil, reason: nil },
        { flag: "--summary", api_field: "contents.summary", deprecated: false, replacement: nil, reason: nil },
        { flag: "--summary-query", api_field: "contents.summary.query", deprecated: false, replacement: nil, reason: nil },
        { flag: "--summary-schema", api_field: "contents.summary.schema", deprecated: false, replacement: nil, reason: nil },
        { flag: "--context", api_field: "contents.context", deprecated: true, replacement: "--highlights or --text", reason: nil },
        { flag: "--context-max-characters", api_field: "contents.context.maxCharacters", deprecated: true,
          replacement: nil, reason: "it sets the length of --context, which is deprecated" },
        { flag: "--subpages", api_field: "contents.subpages", deprecated: true,
          replacement: "exa-ai get-contents --subpages", reason: nil },
        { flag: "--subpage-target", api_field: "contents.subpageTarget", deprecated: true,
          replacement: "exa-ai get-contents --subpage-target", reason: nil },
        { flag: "--links", api_field: "contents.extras.links", deprecated: false, replacement: nil, reason: nil },
        { flag: "--image-links", api_field: "contents.extras.imageLinks", deprecated: false, replacement: nil, reason: nil },
        { flag: "--highlights", api_field: "contents.highlights", deprecated: false, replacement: nil, reason: nil },
        { flag: "--highlights-max-characters", api_field: "contents.highlights.maxCharacters", deprecated: false,
          replacement: nil, reason: nil },
        { flag: "--highlights-num-sentences", api_field: "contents.highlights.numSentences", deprecated: true,
          replacement: "--highlights-max-characters", reason: nil },
        { flag: "--highlights-per-url", api_field: "contents.highlights.highlightsPerUrl", deprecated: true,
          replacement: nil, reason: "the API ignores it" },
        { flag: "--highlights-query", api_field: "contents.highlights.query", deprecated: false, replacement: nil, reason: nil },
        { flag: "--livecrawl", api_field: ["contents.maxAgeHours", "contents.livecrawlTimeout"].freeze,
          deprecated: true, replacement: "--max-age-hours 0 --livecrawl-timeout 5000", reason: nil },
        { flag: "--livecrawl-timeout", api_field: "contents.livecrawlTimeout", deprecated: false, replacement: nil, reason: nil },
        { flag: "--max-age-hours", api_field: "contents.maxAgeHours", deprecated: false, replacement: nil, reason: nil },
        { flag: "--snapshot-as-of", api_field: "contents.snapshotAsOf", deprecated: false, replacement: nil, reason: nil },
        { flag: "--additional-queries", api_field: "additionalQueries", deprecated: false, replacement: nil, reason: nil },
        { flag: "--output-schema", api_field: "outputSchema", deprecated: false, replacement: nil, reason: nil },
        { flag: "--user-location", api_field: "userLocation", deprecated: false, replacement: nil, reason: nil },
        { flag: "--objective", api_field: "objective", deprecated: false, replacement: nil, reason: nil },
        { flag: "--user-identifier", api_field: "userIdentifier", deprecated: false, replacement: nil, reason: nil },
        { flag: "--compliance", api_field: "compliance", deprecated: false, replacement: nil, reason: nil },
        { flag: "--system-prompt", api_field: "systemPrompt", deprecated: false, replacement: nil, reason: nil },
        { flag: "--moderation", api_field: "moderation", deprecated: false, replacement: nil, reason: nil },
        { flag: "--api-key", api_field: nil, deprecated: false, replacement: nil, reason: nil },
        { flag: "--output-format", api_field: nil, deprecated: false, replacement: nil, reason: nil },
        { flag: "--print-request", api_field: nil, deprecated: false, replacement: nil, reason: nil },
        { flag: "--strict", api_field: nil, deprecated: false, replacement: nil, reason: nil },
        { flag: "--flags-json", api_field: nil, deprecated: false, replacement: nil, reason: nil },
        { flag: "--help", api_field: nil, deprecated: false, replacement: nil, reason: nil }
      ].map(&:freeze).freeze

      def self.parse(argv)
        new(argv).parse
      end

      # A country code stays a string. An argument that starts with "{" is
      # parsed as a JSON object, and one that starts with "@" is read as a
      # JSON file, the way --output-schema works. Callers check for a missing
      # value first with Base.text_value, so value is never nil. Bad JSON or
      # an unreadable file exits 1 with one error line that names
      # --user-location.
      def self.parse_user_location(value)
        return Base.parse_json_or_file("--user-location", value) if value.start_with?("@", "{")

        value
      end

      def initialize(argv)
        @argv = argv
        @args = {
          output_format: "json",
          api_key: nil,
          deprecated_flags: []
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
          if arg.start_with?("--")
            entry = FLAGS.find { |candidate| candidate[:flag] == arg }
            Exa::CLI::Base.reject_unknown_option(arg) unless entry
            @args[:deprecated_flags] << entry if entry[:deprecated]
          end

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
            search_type = Exa::CLI::Base.text_value("--type", @argv[i + 1])
            validate_search_type(search_type)
            @args[:type] = search_type
            i += 2
          when "--category"
            category = Exa::CLI::Base.text_value("--category", @argv[i + 1])
            validate_category(category)
            @args[:category] = category
            i += 2
          when "--include-domains"
            @args[:include_domains] = Exa::CLI::Base.text_value("--include-domains", @argv[i + 1]).split(",").map(&:strip)
            i += 2
          when "--exclude-domains"
            @args[:exclude_domains] = Exa::CLI::Base.text_value("--exclude-domains", @argv[i + 1]).split(",").map(&:strip)
            i += 2
          when "--api-key"
            @args[:api_key] = Exa::CLI::Base.text_value("--api-key", @argv[i + 1])
            i += 2
          when "--output-format"
            @args[:output_format] = Exa::CLI::Base.text_value("--output-format", @argv[i + 1])
            i += 2
          when "--start-published-date"
            @args[:start_published_date] = Exa::CLI::Base.text_value("--start-published-date", @argv[i + 1])
            i += 2
          when "--end-published-date"
            @args[:end_published_date] = Exa::CLI::Base.text_value("--end-published-date", @argv[i + 1])
            i += 2
          when "--start-crawl-date"
            @args[:start_crawl_date] = Exa::CLI::Base.text_value("--start-crawl-date", @argv[i + 1])
            i += 2
          when "--end-crawl-date"
            @args[:end_crawl_date] = Exa::CLI::Base.text_value("--end-crawl-date", @argv[i + 1])
            i += 2
          when "--include-text"
            @args[:include_text] ||= []
            @args[:include_text] << Exa::CLI::Base.text_value("--include-text", @argv[i + 1])
            i += 2
          when "--exclude-text"
            @args[:exclude_text] ||= []
            @args[:exclude_text] << Exa::CLI::Base.text_value("--exclude-text", @argv[i + 1])
            i += 2
          when "--additional-queries"
            @args[:additional_queries] ||= []
            @args[:additional_queries] << Exa::CLI::Base.text_value("--additional-queries", @argv[i + 1])
            i += 2
          when "--output-schema"
            @args[:output_schema] = Exa::CLI::Base.parse_json_or_file("--output-schema", @argv[i + 1])
            i += 2
          when "--user-location"
            @args[:user_location] = self.class.parse_user_location(Exa::CLI::Base.text_value("--user-location", @argv[i + 1]))
            i += 2
          when "--objective"
            @args[:objective] = Exa::CLI::Base.text_value("--objective", @argv[i + 1])
            i += 2
          when "--user-identifier"
            @args[:user_identifier] = Exa::CLI::Base.text_value("--user-identifier", @argv[i + 1])
            i += 2
          when "--compliance"
            compliance = Exa::CLI::Base.text_value("--compliance", @argv[i + 1])
            validate_compliance(compliance)
            @args[:compliance] = compliance
            i += 2
          when "--system-prompt"
            @args[:system_prompt] = Exa::CLI::Base.text_value("--system-prompt", @argv[i + 1])
            i += 2
          when "--moderation"
            @args[:moderation] = true
            i += 1
          when "--print-request"
            @args[:print_request] = true
            i += 1
          when "--strict"
            @args[:strict] = true
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

      # Raises ArgumentError unless search_type is a value the API accepts.
      # The message names the flag, so exa-ai search prints it as is.
      def validate_search_type(search_type)
        return if VALID_SEARCH_TYPES.include?(search_type)

        raise ArgumentError, "--type must be one of: #{VALID_SEARCH_TYPES.join(', ')}"
      end

      # Raises ArgumentError unless category is a value the API accepts.
      # The message names the flag, so exa-ai search prints it as is.
      def validate_category(category)
        return if VALID_CATEGORIES.include?(category)

        raise ArgumentError, "--category must be one of: #{VALID_CATEGORIES.map { |c| "\"#{c}\"" }.join(', ')}"
      end

      # Raises ArgumentError unless compliance is a value the API accepts.
      # The message names the flag, so exa-ai search prints it as is.
      def validate_compliance(compliance)
        return if VALID_COMPLIANCE.include?(compliance)

        raise ArgumentError, "--compliance must be one of: #{VALID_COMPLIANCE.join(', ')}"
      end
    end
  end
end
