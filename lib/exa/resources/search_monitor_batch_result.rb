module Exa
  module Resources
    # Result of POST /monitors/batch. Repeat the call until has_more is false.
    class SearchMonitorBatchResult < Struct.new(:action, :affected, :ids, :dry_run, :has_more, keyword_init: true)
      def initialize(action:, affected:, ids:, dry_run:, has_more:)
        super
        freeze
      end
    end
  end
end
