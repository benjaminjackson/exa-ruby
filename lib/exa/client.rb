# frozen_string_literal: true

module Exa
  # Main client for interacting with the Exa.ai API
  #
  # Provides methods for all supported Exa.ai operations including search,
  # content retrieval, answer generation, and agent runs.
  #
  # @example Basic usage
  #   client = Exa::Client.new(api_key: "your-key")
  #   results = client.search("ruby on rails")
  #   results.results.each { |r| puts r.title }
  #
  # @example Using configuration
  #   Exa.configure { |config| config.api_key = "your-key" }
  #   client = Exa::Client.new
  class Client
    # Initialize a new Exa client
    #
    # @param api_key [String, nil] API key for authentication. Falls back to Exa.api_key if not provided
    # @param options [Hash] Connection options
    # @option options [String] :base_url Custom API base URL (default: https://api.exa.ai)
    # @option options [Integer] :timeout Request timeout in seconds (default: 30)
    # @raise [ConfigurationError] If API key is not provided and not configured
    def initialize(api_key: nil, **options)
      @api_key = api_key || Exa.api_key
      @options = options

      validate_api_key!
    end

    # Execute a search query
    #
    # @param query [String] Search query
    # @param params [Hash] Additional search parameters
    # @option params [String] :type Search type (web, news, etc.)
    # @option params [Array<String>] :include_domains Domains to include in results
    # @option params [Array<String>] :exclude_domains Domains to exclude from results
    # @option params [Integer] :num_results Number of results to return
    #
    # Deprecated and legacy parameters still work. The API reports some of
    # them in the response's warnings:
    # - :type "fast" and "instant" are legacy; use "lite". "deep-reasoning"
    #   is legacy; use "deep".
    # - :start_crawl_date and :end_crawl_date are deprecated. The API ignores
    #   them and adds an IGNORED_FIELD warning.
    # - :include_text and :exclude_text are deprecated.
    # - :context (and :context_max_characters) is deprecated; use :highlights
    #   or :text.
    # - :highlights_num_sentences (highlights numSentences) is deprecated; use
    #   :highlights_max_characters. :highlights_per_url is deprecated and
    #   ignored by the API.
    # - :subpages and :subpage_target are deprecated on search; pass them to
    #   #get_contents instead.
    # - :livecrawl is deprecated; use :max_age_hours. :crawled_before_date is
    #   deprecated; use :snapshot_as_of, an alias with identical behavior.
    # @return [Resources::SearchResult] Search results with metadata
    def search(query, **params)
      Services::Search.new(connection, query: query, **params).call
    end

    # Find similar content to a given URL
    #
    # @deprecated The API marks /findSimilar as deprecated. Use #search with
    #   a query that describes the source page instead. This method still
    #   works. Its :start_crawl_date, :end_crawl_date, :include_text,
    #   :exclude_text, :context, :livecrawl and :crawled_before_date options
    #   are deprecated as on #search.
    # @param url [String] URL to find similar content for
    # @param options [Hash] Search options
    # @option options [Integer] :num_results Number of results to return
    # @return [Resources::FindSimilarResult] Similar results
    def find_similar(url, **options)
      Services::FindSimilar.new(connection, url: url, **options).call
    end

    # Get full page contents for URLs
    #
    # @param urls [Array<String>, String, nil] URL or URLs to fetch contents for,
    #   positional or as the urls: keyword. Leave out when passing :ids
    #   instead; urls is sent only when given. Nil and empty count as missing.
    # @param options [Hash] Fetch options
    # @option options [Array<String>] :ids Document IDs from earlier searches
    # @option options [Boolean, Hash] :context Deprecated; use :highlights or
    #   :text. The highlights numSentences and highlightsPerUrl keys are also
    #   deprecated; use maxCharacters. :subpages and :subpage_target stay
    #   valid here.
    # @option options [String] :livecrawl Deprecated; use :max_age_hours.
    # @option options [String] :crawled_before_date Deprecated; use
    #   :snapshot_as_of, an alias with identical behavior.
    # @raise [ArgumentError] when neither urls nor :ids is given
    # @return [Resources::ContentsResult] Page contents with metadata
    def get_contents(urls = nil, **options)
      urls ||= options.delete(:urls)
      urls = nil if urls.respond_to?(:empty?) && urls.empty?
      ids = options[:ids]
      ids = nil if ids.respond_to?(:empty?) && ids.empty?
      raise ArgumentError, "get_contents requires urls or the ids: option" unless urls || ids

      options = { urls: urls }.merge(options) if urls
      Services::GetContents.new(connection, **options).call
    end

    # Get AI-generated answers to a query
    #
    # @param query [String] Question or query
    # @param options [Hash] Answer options
    # @option options [String] :format Response format (default: standard)
    # @return [Resources::Answer] AI-generated answer with sources
    def answer(query, **options)
      Services::Answer.new(connection, query: query, **options).call
    end

    # Stream AI-generated answers to a query
    #
    # Returns partial answer chunks as they are generated by the API.
    #
    # @param query [String] Question or query
    # @param options [Hash] Answer options
    # @option options [Boolean] :text Include full text content (default: false)
    # @option options [Hash] :output_schema JSON schema for structured output
    # @yield [chunk] Yields each answer chunk as it arrives
    # @yieldparam chunk [Hash] Partial answer data with {"answer" => "text"}
    # @return [void]
    def answer_stream(query, **options, &block)
      Services::AnswerStream.new(connection, query: query, **options).call(&block)
    end

    # Stream a search with a synthesized answer
    #
    # The API streams /search only when an output schema is set, so
    # :output_schema is required.
    #
    # @param query [String] Search query
    # @param params [Hash] Search parameters, as for #search
    # @option params [Hash] :output_schema JSON schema for the synthesized output (required)
    # @yield [chunk] Yields each server-sent event as it arrives
    # @yieldparam chunk [Hash] Event with a "type" of text-delta, grounding,
    #   results, stream-reset or done. Chunks are yielded as received, so a
    #   summary requested with a schema arrives as a JSON string, not a Hash.
    # @raise [ArgumentError] when :output_schema is missing
    # @raise [Exa::Error] when the stream sends an error event
    # @return [void]
    def search_stream(query, **params, &block)
      Services::SearchStream.new(connection, query: query, **params).call(&block)
    end

    # Create a new agent run
    #
    # @param query [String] The query or task for the agent to execute (required)
    # @param params [Hash] Additional run parameters
    # @option params [Hash] :input Input data for the agent run
    # @option params [Array<Hash>] :data_sources Data sources for the agent run (up to 5)
    # @option params [Hash] :budget Spend limits, for example
    #   +{max_cost_dollars: 5.0, max_duration_seconds: 1800}+
    # @option params [String] :user_identifier Your identifier for the end user of this run
    # @option params [Hash] :metadata Custom metadata
    #
    # The parameter converter turns snake_case keys into camelCase at every depth,
    # so +budget+, +input+ and +data_sources+ items can use snake_case keys. Keys
    # inside +metadata+ and +output_schema+ are user data and go out exactly as given.
    # @return [Resources::AgentRun] The newly created agent run
    def agent_run_create(query:, **params)
      Services::AgentRunCreate.new(connection, query: query, **params).call
    end

    # Stream an agent run, yielding chunks as they arrive
    #
    # @param query [String] The query or task for the agent to execute (required)
    # @param params [Hash] Additional run parameters
    # @option params [Hash] :input Input data for the agent run
    # @option params [Array<Hash>] :data_sources Data sources for the agent run (up to 5)
    # @option params [Hash] :budget Spend limits, for example
    #   +{max_cost_dollars: 5.0, max_duration_seconds: 1800}+
    # @option params [String] :user_identifier Your identifier for the end user of this run
    # @option params [Hash] :metadata Custom metadata
    #
    # The parameter converter turns snake_case keys into camelCase at every depth,
    # so +budget+, +input+ and +data_sources+ items can use snake_case keys. Keys
    # inside +metadata+ and +output_schema+ are user data and go out exactly as given.
    #
    # @yield [event_type, data, event_id] Yields each streamed event as it arrives.
    #   Blocks and procs that take only (event_type, data) keep working; a lambda
    #   passed with & must accept three arguments.
    # @yieldparam event_type [String] Event name, for example "agent_run.completed"
    # @yieldparam data [Hash] The event's JSON payload
    # @yieldparam event_id [String, nil] The SSE id of the event, if the server sent one
    # @return [Resources::AgentRun, nil] The final run from the terminal event, or nil
    #   if the stream ended before one arrived
    def agent_run_stream(query:, **params, &block)
      Services::AgentRunStream.new(connection, query: query, **params).call(&block)
    end

    # Get the status and results of an agent run
    #
    # @param run_id [String] Agent run ID
    # @return [Resources::AgentRun] Agent run with current status and results
    def agent_run_get(run_id)
      Services::AgentRunGet.new(connection, run_id: run_id).call
    end

    # List all agent runs
    #
    # @param params [Hash] Listing parameters
    # @option params [Integer] :limit Maximum number of runs to return
    # @option params [String] :cursor Cursor for pagination
    # @return [Resources::AgentRunList] List of agent runs
    def agent_run_list(**params)
      Services::AgentRunList.new(connection, **params).call
    end

    # Cancel an in-progress agent run. The run ends at once with no results.
    #
    # @param run_id [String] Agent run ID
    # @return [Resources::AgentRun] The cancelled agent run
    def agent_run_cancel(run_id)
      Services::AgentRunCancel.new(connection, run_id: run_id).call
    end

    # Stop an in-progress agent run early. Unlike cancel, the run completes
    # with stop reason "stopped" and keeps the results gathered so far. The API
    # supports this only for runs with effort high, xhigh or ultra.
    #
    # @param run_id [String] Agent run ID
    # @return [Resources::AgentRun] The stopped agent run
    def agent_run_stop(run_id)
      Services::AgentRunStop.new(connection, run_id: run_id).call
    end

    # Delete an agent run
    #
    # @param run_id [String] Agent run ID
    # @return [Resources::AgentRunDeletion] The id of the deleted run and deleted: true
    def agent_run_delete(run_id)
      Services::AgentRunDelete.new(connection, run_id: run_id).call
    end

    # List events for an agent run
    #
    # @param run_id [String] Agent run ID
    # @param params [Hash] Listing parameters
    # @option params [Integer] :limit Maximum number of events to return
    # @option params [String] :cursor Cursor for pagination
    # @option params [String] :last_event_id Replay the events after this event id.
    #   The call then asks for server-sent events (Accept: text/event-stream with a
    #   Last-Event-ID header) and reads the whole response before it returns. The
    #   docs do not say whether the server closes the stream for a run that is still
    #   in progress, so for such a run this call may block until the run ends.
    #   If no data arrives within the connection's read timeout, the call raises
    #   Faraday::TimeoutError.
    #   The result has items {"id", "event", "data"}, has_more false and no cursor.
    # @return [Resources::AgentRunEventList] Agent run events with has_more and next_cursor
    def agent_run_events(run_id, **params)
      Services::AgentRunEvents.new(connection, run_id: run_id, **params).call
    end

    # Create a search monitor: a scheduled Exa search that posts new results to a webhook.
    # This is the /monitors API.
    #
    # @param search [Hash] Search to run (required: :query; optional :num_results,
    #   :include_domains, :exclude_domains, :contents)
    # @param webhook [Hash] Webhook to call (required: :url; optional :events)
    # @param params [Hash] Additional parameters
    # @option params [Hash] :trigger Schedule, e.g. { type: "interval", period: "1d" }.
    #   Without it the monitor runs only when triggered by hand.
    # @option params [String] :name Monitor name
    # @option params [Hash] :output_schema JSON schema for structured output (sent as given)
    # @option params [Hash] :metadata Custom metadata (sent as given)
    # @return [Resources::SearchMonitor] The new monitor. Its webhook_secret is returned only once.
    def search_monitor_create(search:, webhook:, **params)
      Services::SearchMonitors::Create.new(connection, search: search, webhook: webhook, **params).call
    end

    # List search monitors
    #
    # @param params [Hash] Filters and pagination
    # @option params [String] :status Filter by status (active, paused, disabled)
    # @option params [String] :name Filter by name (case-insensitive substring)
    # @option params [Hash] :metadata Filter by metadata key-value pairs
    # @option params [Integer] :limit Results per page
    # @option params [String] :cursor Cursor for pagination
    # @return [Resources::SearchMonitorList] One page of monitors
    def search_monitor_list(**params)
      Services::SearchMonitors::List.new(connection, **params).call
    end

    # Get a search monitor
    #
    # @param id [String] Monitor ID
    # @return [Resources::SearchMonitor] The monitor
    def search_monitor_get(id)
      Services::SearchMonitors::Get.new(connection, id: id).call
    end

    # Update a search monitor. Only the keys given are changed.
    #
    # @param id [String] Monitor ID
    # @param params [Hash] Fields to change: :name, :status, :search, :trigger,
    #   :webhook, :output_schema, :metadata. Pass trigger: nil to remove the schedule.
    # @return [Resources::SearchMonitor] The updated monitor
    def search_monitor_update(id, **params)
      Services::SearchMonitors::Update.new(connection, id: id, **params).call
    end

    # Delete a search monitor
    #
    # @param id [String] Monitor ID
    # @return [Resources::SearchMonitor] The deleted monitor
    def search_monitor_delete(id)
      Services::SearchMonitors::Delete.new(connection, id: id).call
    end

    # Run a search monitor now. Works when its status is active or paused.
    #
    # @param id [String] Monitor ID
    # @return [Resources::SearchMonitorTriggerResult] Whether a run started
    def search_monitor_trigger(id)
      Services::SearchMonitors::Trigger.new(connection, id: id).call
    end

    # Delete, pause or unpause every search monitor that matches a filter.
    # Call again until has_more is false.
    #
    # @param action [String] "delete", "pause" or "unpause"
    # @param filter [Hash] :name, :status and/or :metadata to match
    # @param dry_run [Boolean] Only report what would change. True unless you pass false.
    # @param limit [Integer, nil] Maximum monitors to change in this call
    # @return [Resources::SearchMonitorBatchResult] What changed, or would change
    def search_monitor_batch(action:, filter:, dry_run: true, limit: nil)
      Services::SearchMonitors::Batch.new(connection, action: action, filter: filter, dry_run: dry_run, limit: limit).call
    end

    # List the runs of a search monitor
    #
    # @param monitor_id [String] Monitor ID
    # @param params [Hash] Pagination: :limit, :cursor
    # @return [Resources::SearchMonitorList] One page of runs
    def search_monitor_runs_list(monitor_id, **params)
      Services::SearchMonitors::RunsList.new(connection, monitor_id: monitor_id, **params).call
    end

    # Get one run of a search monitor
    #
    # @param monitor_id [String] Monitor ID
    # @param run_id [String] Run ID
    # @return [Resources::SearchMonitorRun] The run
    def search_monitor_runs_get(monitor_id, run_id)
      Services::SearchMonitors::RunsGet.new(connection, monitor_id: monitor_id, run_id: run_id).call
    end

    # Search code repositories
    #
    # @deprecated The Exa API spec no longer lists POST /context. The
    #   endpoint still answers and this method still works, but no
    #   replacement is named. For code lookup, use #search.
    # @param query [String] Code search query
    # @param params [Hash] Search parameters
    # @option params [Array<String>] :languages Programming languages to search
    # @return [Resources::SearchResult] Code search results
    def context(query, **params)
      Services::Context.new(connection, query: query, **params).call
    end

    private

    def connection
      @connection ||= Connection.build(
        api_key: @api_key,
        **connection_options
      )
    end

    def connection_options
      options = {}
      options[:base_url] = @options[:base_url] if @options[:base_url]
      options[:timeout] = @options[:timeout] if @options[:timeout]
      options[:debug] = true if ENV["EXA_DEBUG"]
      options
    end

    def validate_api_key!
      return if @api_key && !@api_key.empty?

      raise ConfigurationError, "API key is required. Set it with Exa.configure or pass it to Client.new"
    end
  end
end
