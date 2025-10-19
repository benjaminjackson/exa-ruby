# frozen_string_literal: true

module Exa
  module Resources
    # Represents an answer response from the Exa API
    #
    # This class wraps the JSON response from the /answer endpoint and provides
    # a Ruby-friendly interface for accessing the generated answer and citations.
    class Answer < Struct.new(:answer, :citations, :cost_dollars, keyword_init: true)
      def initialize(answer:, citations: [], cost_dollars: nil)
        super
        freeze
      end

      def to_h
        { answer: answer, citations: citations, cost_dollars: cost_dollars }
      end
    end
  end
end
