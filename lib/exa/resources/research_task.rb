module Exa
  module Resources
    class ResearchTask < Struct.new(
      :research_id, :created_at, :status, :model, :instructions,
      :output_schema, :events, :output, :cost_dollars, :finished_at,
      :error, keyword_init: true
    )
      def initialize(research_id:, created_at:, status:, instructions:, model: nil, output_schema: nil, events: nil, output: nil, cost_dollars: nil, finished_at: nil, error: nil)
        super
        freeze
      end

      def pending? = status == 'pending'
      def running? = status == 'running'
      def completed? = status == 'completed'
      def failed? = status == 'failed'
      def canceled? = status == 'canceled'

      def finished? = !running? && !pending?

      def to_h
        result = {
          research_id: research_id,
          created_at: created_at,
          status: status,
          instructions: instructions
        }
        result[:model] = model if model
        result[:output_schema] = output_schema if output_schema
        result[:events] = events if events
        result[:output] = output if output
        result[:cost_dollars] = cost_dollars if cost_dollars
        result[:finished_at] = finished_at if finished_at
        result[:error] = error if error
        result
      end
    end
  end
end
