# frozen_string_literal: true

module Exa
  module CLI
    # The contents flags that exa-ai-search and exa-ai-find-similar share:
    # how each flag is read from the command line, how the flags become the
    # request's contents hash, and their lines in the help text.
    module ContentsFlags
      VALID_TEXT_VERBOSITY = ["compact", "standard", "full"].freeze

      # The "Content Extraction" lines of the help text, each with its indent.
      HELP = <<~HELP.gsub(/^/, "  ").chomp
        --text                       Include full webpage text
        --text-max-characters N      Max characters for webpage text
        --text-verbosity LEVEL       Text verbosity: compact, standard, or full
        --include-html-tags          Include HTML tags in text extraction
        --summary                    Include AI-generated summary
        --summary-query PROMPT       Custom prompt for summary generation
        --summary-schema FILE        JSON schema for summary structure (@file syntax)
        --context                    Deprecated: use --highlights or --text instead
                                     (format results as one context string)
        --context-max-characters N   Deprecated: max characters for context string
        --subpages N                 Deprecated on search: crawl subpages with
                                     exa-ai get-contents --subpages instead
        --subpage-target PHRASE      Deprecated on search: use
                                     exa-ai get-contents --subpage-target instead
        --links N                    Number of links to extract per result
        --image-links N              Number of image links to extract
        --highlights                 Include text highlights in results
        --highlights-max-characters N  Max characters per highlight
        --highlights-num-sentences N   Deprecated: use --highlights-max-characters instead
        --highlights-per-url N       Deprecated: the API ignores it
        --highlights-query QUERY     Custom query for highlight extraction
        --livecrawl                  Enable livecrawl (sets maxAgeHours=0, livecrawlTimeout=5000)
        --livecrawl-timeout N        Livecrawl timeout in milliseconds (overrides --livecrawl default)
        --max-age-hours N            Maximum age of results in hours
        --snapshot-as-of DATE        Return page contents as of this time (ISO 8601)
      HELP

      # Reads the contents flag at argv[index] into args and returns the index
      # of the next argument. Returns nil when argv[index] is not a contents flag.
      def self.parse(argv, index, args)
        case argv[index]
        when "--text"
          args[:text] = true
          index + 1
        when "--text-max-characters"
          args[:text_max_characters] = Base.parse_integer("--text-max-characters", argv[index + 1])
          index + 2
        when "--text-verbosity"
          verbosity = argv[index + 1]
          validate_text_verbosity(verbosity)
          args[:text_verbosity] = verbosity
          index + 2
        when "--include-html-tags"
          args[:include_html_tags] = true
          index + 1
        when "--summary"
          args[:summary] = true
          index + 1
        when "--summary-query"
          args[:summary_query] = Base.text_value("--summary-query", argv[index + 1])
          index + 2
        when "--summary-schema"
          args[:summary_schema] = Base.parse_json_or_file("--summary-schema", argv[index + 1])
          index + 2
        when "--context"
          args[:context] = true
          index + 1
        when "--context-max-characters"
          args[:context_max_characters] = Base.parse_integer("--context-max-characters", argv[index + 1])
          index + 2
        when "--subpages"
          args[:subpages] = Base.parse_integer("--subpages", argv[index + 1])
          index + 2
        when "--subpage-target"
          args[:subpage_target] ||= []
          args[:subpage_target] << Base.text_value("--subpage-target", argv[index + 1])
          index + 2
        when "--links"
          args[:links] = Base.parse_integer("--links", argv[index + 1])
          index + 2
        when "--image-links"
          args[:image_links] = Base.parse_integer("--image-links", argv[index + 1])
          index + 2
        when "--highlights"
          args[:highlights] = true
          index + 1
        when "--highlights-max-characters"
          args[:highlights_max_characters] = Base.parse_integer("--highlights-max-characters", argv[index + 1])
          index + 2
        when "--highlights-num-sentences"
          args[:highlights_num_sentences] = Base.parse_integer("--highlights-num-sentences", argv[index + 1])
          index + 2
        when "--highlights-per-url"
          args[:highlights_per_url] = Base.parse_integer("--highlights-per-url", argv[index + 1])
          index + 2
        when "--highlights-query"
          args[:highlights_query] = Base.text_value("--highlights-query", argv[index + 1])
          index + 2
        when "--livecrawl"
          args[:livecrawl] = true
          index + 1
        when "--livecrawl-timeout"
          args[:livecrawl_timeout] = Base.parse_integer("--livecrawl-timeout", argv[index + 1])
          index + 2
        when "--max-age-hours"
          args[:max_age_hours] = Base.parse_integer("--max-age-hours", argv[index + 1])
          index + 2
        when "--snapshot-as-of"
          args[:snapshot_as_of] = Base.text_value("--snapshot-as-of", argv[index + 1])
          index + 2
        end
      end

      # Raises ArgumentError unless verbosity is a value the API accepts.
      def self.validate_text_verbosity(verbosity)
        return if VALID_TEXT_VERBOSITY.include?(verbosity)

        raise ArgumentError, "Text verbosity must be one of: #{VALID_TEXT_VERBOSITY.join(', ')}"
      end

      # Builds the contents hash from the parsed flags, or nil when no
      # contents flag is set. --snapshot-as-of is not in it: each command
      # sends snapshot_as_of itself.
      def self.build(args)
        contents = {}

        # Text options
        if args[:text]
          if args[:text_max_characters] || args[:include_html_tags] || args[:text_verbosity]
            contents[:text] = {}
            contents[:text][:max_characters] = args[:text_max_characters] if args[:text_max_characters]
            contents[:text][:include_html_tags] = args[:include_html_tags] if args[:include_html_tags]
            contents[:text][:verbosity] = args[:text_verbosity] if args[:text_verbosity]
          else
            contents[:text] = true
          end
        end

        # Summary options
        if args[:summary]
          if args[:summary_query] || args[:summary_schema]
            contents[:summary] = {}
            contents[:summary][:query] = args[:summary_query] if args[:summary_query]
            contents[:summary][:schema] = args[:summary_schema] if args[:summary_schema]
          else
            contents[:summary] = true
          end
        end

        # Context options
        if args[:context]
          if args[:context_max_characters]
            contents[:context] = { max_characters: args[:context_max_characters] }
          else
            contents[:context] = true
          end
        end

        # Subpages options
        contents[:subpages] = args[:subpages] if args[:subpages]
        contents[:subpage_target] = args[:subpage_target] if args[:subpage_target]

        # Extras options
        if args[:links] || args[:image_links]
          contents[:extras] = {}
          contents[:extras][:links] = args[:links] if args[:links]
          contents[:extras][:image_links] = args[:image_links] if args[:image_links]
        end

        # Highlights options
        if args[:highlights]
          highlight_opts = %i[highlights_max_characters highlights_num_sentences highlights_per_url highlights_query]
          if highlight_opts.any? { |k| args[k] }
            contents[:highlights] = {}
            contents[:highlights][:max_characters] = args[:highlights_max_characters] if args[:highlights_max_characters]
            contents[:highlights][:num_sentences] = args[:highlights_num_sentences] if args[:highlights_num_sentences]
            contents[:highlights][:highlights_per_url] = args[:highlights_per_url] if args[:highlights_per_url]
            contents[:highlights][:query] = args[:highlights_query] if args[:highlights_query]
          else
            contents[:highlights] = true
          end
        end

        # Livecrawl options
        if args[:livecrawl]
          contents[:max_age_hours] = args[:max_age_hours].nil? ? 0 : args[:max_age_hours]
          contents[:livecrawl_timeout] = args[:livecrawl_timeout].nil? ? 5000 : args[:livecrawl_timeout]
        else
          contents[:livecrawl_timeout] = args[:livecrawl_timeout] if args[:livecrawl_timeout]
          contents[:max_age_hours] = args[:max_age_hours] if args[:max_age_hours]
        end

        contents.empty? ? nil : contents
      end
    end
  end
end
