# frozen_string_literal: true

module Exa
  module Constants
    module Websets
      # Valid entity types for websets
      ENTITY_TYPES = %w[company person article research_paper custom].freeze

      # Valid enrichment formats
      ENRICHMENT_FORMATS = %w[text date number options email phone url].freeze

      # Valid source types for imports and exclusions
      SOURCE_TYPES = %w[import webset].freeze

      # Valid import formats
      IMPORT_FORMATS = %w[csv].freeze
    end
  end
end
