# frozen_string_literal: true

require_relative "agent_run_stream"
require_relative "../resources/agent_run_event_list"

module Exa
  module Services
    class AgentRunEvents
      def initialize(connection, run_id:, last_event_id: nil, **params)
        @connection = connection
        @run_id = run_id
        @last_event_id = last_event_id
        @params = params
      end

      def call
        return replay_events if @last_event_id

        response = @connection.get("/agent/runs/#{@run_id}/events", @params)
        event_list_from_json(response.body)
      end

      private

      # Confirmed live: GET /agent/runs/{id}/events returns a paginated list
      # {object: "list", data: [...], hasMore, nextCursor}.
      def event_list_from_json(body)
        Resources::AgentRunEventList.new(
          data: body["data"] || [],
          has_more: body["hasMore"],
          next_cursor: body["nextCursor"]
        )
      end

      # Replays the events after @last_event_id as server-sent events. Reads
      # the whole response, then returns the same list shape as JSON mode,
      # with items {"id", "event", "data"}. SSE replay has no cursor, so
      # has_more is false and next_cursor is nil. If the server ignores the
      # Accept header and answers with JSON, the JSON middleware has already
      # parsed it into a Hash, which is read as in JSON mode.
      def replay_events
        response = @connection.get("/agent/runs/#{@run_id}/events", @params) do |req|
          req.headers["Accept"] = "text/event-stream"
          req.headers["Last-Event-ID"] = @last_event_id.to_s
        end

        return event_list_from_json(response.body) unless response.body.is_a?(String)

        frames = response.body.gsub("\r\n", "\n").split("\n\n")
        parsed_frames = frames.filter_map { |frame| AgentRunStream.parse_frame(frame) }
        events = parsed_frames.map { |event_type, data, event_id| { "id" => event_id, "event" => event_type, "data" => data } }

        Resources::AgentRunEventList.new(data: events, has_more: false, next_cursor: nil)
      end
    end
  end
end
