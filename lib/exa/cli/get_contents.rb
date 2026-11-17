# frozen_string_literal: true

module Exa
  module CLI
    # Data for exa-ai get-contents. The parsing stays in exe/exa-ai-get-contents.
    module GetContents
      # Every flag exa-ai get-contents accepts. Public API: wrappers read it
      # here or through `exa-ai get-contents --flags-json`, and the exe
      # rejects any "--" argument that is not in it. api_field is the request
      # body path the flag sets (nil when it sets none); content fields sit
      # at the top level of the body, not under contents. replacement is what
      # to type instead of a deprecated flag. --livecrawl,
      # --highlights-num-sentences and --highlights-per-url are left out on
      # purpose: get-contents does not take them.
      FLAGS = [
        { flag: "--text", api_field: "text", deprecated: false, replacement: nil },
        { flag: "--text-max-characters", api_field: "text.maxCharacters", deprecated: false, replacement: nil },
        { flag: "--include-html-tags", api_field: "text.includeHtmlTags", deprecated: false, replacement: nil },
        { flag: "--text-verbosity", api_field: "text.verbosity", deprecated: false, replacement: nil },
        { flag: "--summary", api_field: "summary", deprecated: false, replacement: nil },
        { flag: "--summary-query", api_field: "summary.query", deprecated: false, replacement: nil },
        { flag: "--summary-schema", api_field: "summary.schema", deprecated: false, replacement: nil },
        { flag: "--context", api_field: "context", deprecated: true, replacement: "--highlights or --text" },
        { flag: "--context-max-characters", api_field: "context.maxCharacters", deprecated: true, replacement: nil },
        { flag: "--subpages", api_field: "subpages", deprecated: false, replacement: nil },
        { flag: "--subpage-target", api_field: "subpageTarget", deprecated: false, replacement: nil },
        { flag: "--links", api_field: "extras.links", deprecated: false, replacement: nil },
        { flag: "--image-links", api_field: "extras.imageLinks", deprecated: false, replacement: nil },
        { flag: "--highlights", api_field: "highlights", deprecated: false, replacement: nil },
        { flag: "--highlights-query", api_field: "highlights.query", deprecated: false, replacement: nil },
        { flag: "--highlights-max-characters", api_field: "highlights.maxCharacters", deprecated: false, replacement: nil },
        { flag: "--highlights-verbosity", api_field: "highlights.verbosity", deprecated: false, replacement: nil },
        { flag: "--livecrawl-timeout", api_field: "livecrawlTimeout", deprecated: false, replacement: nil },
        { flag: "--max-age-hours", api_field: "maxAgeHours", deprecated: false, replacement: nil },
        { flag: "--snapshot-as-of", api_field: "snapshotAsOf", deprecated: false, replacement: nil },
        { flag: "--ids", api_field: "ids", deprecated: false, replacement: nil },
        { flag: "--user-identifier", api_field: "userIdentifier", deprecated: false, replacement: nil },
        { flag: "--compliance", api_field: "compliance", deprecated: false, replacement: nil },
        { flag: "--api-key", api_field: nil, deprecated: false, replacement: nil },
        { flag: "--output-format", api_field: nil, deprecated: false, replacement: nil },
        { flag: "--print-request", api_field: nil, deprecated: false, replacement: nil },
        { flag: "--flags-json", api_field: nil, deprecated: false, replacement: nil },
        { flag: "--help", api_field: nil, deprecated: false, replacement: nil }
      ].map(&:freeze).freeze
    end
  end
end
