module Exa
  module Resources
    # Result of POST /monitors/{id}/trigger.
    class SearchMonitorTriggerResult < Struct.new(:triggered, keyword_init: true)
      def initialize(triggered:)
        super
        freeze
      end
    end
  end
end
