module Exa
  module Resources
    class AgentRun < Struct.new(
      :id, :object, :status, :stop_reason, :created_at, :completed_at,
      :request, :output, :usage, :cost_dollars, keyword_init: true
    )
      def initialize(id:, object:, status:, stop_reason: nil, created_at: nil, completed_at: nil, request: nil, output: nil, usage: nil, cost_dollars: nil)
        super
        freeze
      end

      def queued?    = status == 'queued'
      def running?   = status == 'running'
      def completed? = status == 'completed'
      def failed?    = status == 'failed'
      def cancelled? = status == 'cancelled'

      def finished? = completed? || failed? || cancelled?

      def to_h
        result = {
          id: id,
          object: object,
          status: status
        }
        result[:stop_reason]  = stop_reason  if stop_reason
        result[:created_at]   = created_at   if created_at
        result[:completed_at] = completed_at if completed_at
        result[:request]      = request      if request
        result[:output]       = output       if output
        result[:usage]        = usage        if usage
        result[:cost_dollars] = cost_dollars if cost_dollars
        result
      end
    end
  end
end
