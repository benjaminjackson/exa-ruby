# Codebase Patterns

Concrete patterns for services, resources, collections and pagination, client methods, CLI commands, tests and errors. The examples are copied from search monitors (`/monitors`) and agent runs, which follow the same patterns as the other endpoints.

## Table of Contents

1. [Service Object Pattern](#service-object-pattern)
2. [Resource Object Pattern](#resource-object-pattern)
3. [List and Pagination Handling](#list-and-pagination-handling)
4. [Client Integration Pattern](#client-integration-pattern)
5. [CLI Command Structure](#cli-command-structure)
6. [Datetime Handling](#datetime-handling)
7. [Test Patterns](#test-patterns)
8. [Error Handling](#error-handling)

---

## Service Object Pattern

### Location Pattern
Services for one API area live in a folder under `lib/exa/services/`. Search monitors:
```
lib/exa/services/search_monitors/
├── batch.rb
├── create.rb
├── delete.rb
├── get.rb
├── list.rb
├── runs_get.rb
├── runs_list.rb
├── trigger.rb
└── update.rb
```
Single-endpoint services sit directly in `lib/exa/services/` (`search.rb`, `answer.rb`, `get_contents.rb`, `agent_run_get.rb`, ...).

### Implementation Pattern

**Basic structure** (`lib/exa/services/search_monitors/get.rb`):
```ruby
# frozen_string_literal: true

require_relative "../../resources/search_monitor"

module Exa
  module Services
    module SearchMonitors
      # GET /monitors/{id}
      class Get
        def initialize(connection, id:)
          @connection = connection
          @id = id
        end

        def call
          response = @connection.get("/monitors/#{@id}")
          Resources::SearchMonitor.from_response(response.body)
        end
      end
    end
  end
end
```

**Key Characteristics:**
- Constructor takes `connection` as first parameter
- Additional parameters passed as keyword arguments
- Single public method: `#call`
- Returns a Resource object (NOT a raw Faraday response)
- The resource is built from the response body by `Resource.from_response`
- No base class inheritance (simple, standalone classes)

**Request shaping:**
A service that sends a body can reshape it in a private method. `lib/exa/services/search_monitors/create.rb` converts the keys of the `search` hash to the API's camelCase with `ParameterConverter` and renames `output_schema`:
```ruby
def initialize(connection, search:, webhook:, **params)
  @connection = connection
  @params = params.merge(search: search, webhook: webhook)
end

def call
  response = @connection.post("/monitors", request_body)
  Resources::SearchMonitor.from_response(response.body)
end

private

# Only the search hash and the top-level output_schema key change case.
# Values of metadata and output_schema go to the API as given.
def request_body
  @params.each_with_object({}) do |(key, value), body|
    case key
    when :search then body[:search] = ParameterConverter.convert(value)
    when :output_schema then body[:outputSchema] = value
    else body[key] = value
    end
  end
end
```

---

## Resource Object Pattern

### Location Pattern
Resources are in `lib/exa/resources/`:
```
lib/exa/resources/
├── search_monitor.rb
├── search_monitor_list.rb
├── search_monitor_run.rb
├── search_monitor_trigger_result.rb
├── search_monitor_batch_result.rb
├── agent_run.rb
├── agent_run_list.rb
└── ... (search_result.rb, answer.rb, contents_result.rb, ...)
```

### Implementation Pattern

**Frozen Struct with Keyword Init** (`lib/exa/resources/search_monitor.rb`):
```ruby
module Exa
  module Resources
    # A scheduled Exa search that sends new results to a webhook (/monitors).
    class SearchMonitor < Struct.new(
      :id, :name, :status, :search, :trigger, :webhook, :output_schema,
      :metadata, :next_run_at, :created_at, :updated_at, :webhook_secret,
      keyword_init: true
    )
      def initialize(id:, name: nil, status: nil, search: nil, trigger: nil, webhook: nil, output_schema: nil,
                     metadata: nil, next_run_at: nil, created_at: nil, updated_at: nil, webhook_secret: nil)
        super
        freeze
      end

      # Build from a raw API response body (camelCase keys).
      def self.from_response(body)
        new(
          id: body["id"],
          name: body["name"],
          # ... one line per field
          webhook_secret: body["webhookSecret"]
        )
      end

      def active?   = status == "active"
      def paused?   = status == "paused"
      def disabled? = status == "disabled"

      def to_h
        super.compact
      end
    end
  end
end
```

**Key Characteristics:**
- Use `Struct.new` with `keyword_init: true`
- Explicit `initialize` method with all fields (optional ones default to `nil`)
- Call `freeze` after `super` for immutability
- `self.from_response(body)` maps the camelCase API body to snake_case fields
- Helper methods for status checks (`active?`, `paused?`, ...)
- `#to_h` returns a hash without nil values
- No datetime parsing: strings are kept as-is from the API

---

## List and Pagination Handling

### Paginated Collections (cursor pagination)

```ruby
# lib/exa/resources/search_monitor_list.rb
module Exa
  module Resources
    # One page of search monitors (GET /monitors) or of their runs (GET /monitors/{id}/runs).
    class SearchMonitorList < Struct.new(:data, :has_more, :next_cursor, keyword_init: true)
      def initialize(data:, has_more:, next_cursor: nil)
        super
        freeze
      end

      def to_h
        {
          data: data.map(&:to_h),
          has_more: has_more,
          next_cursor: next_cursor
        }
      end
    end
  end
end
```

`lib/exa/resources/agent_run_list.rb` and `lib/exa/resources/agent_run_event_list.rb` use the same `data` / `has_more` / `next_cursor` shape.

**API Response Structure:**
```json
{
  "data": [...],
  "hasMore": true,
  "nextCursor": "cursor_abc"
}
```

### Service Implementation for Lists

```ruby
# lib/exa/services/search_monitors/list.rb
class List
  def initialize(connection, **params)
    @connection = connection
    @params = params
  end

  def call
    body = @connection.get("/monitors", @params).body

    Resources::SearchMonitorList.new(
      data: body["data"].map { |monitor| Resources::SearchMonitor.from_response(monitor) },
      has_more: body["hasMore"],
      next_cursor: body["nextCursor"]
    )
  end
end
```

The caller passes `cursor:` and `limit:` in `params` to get the next page.

---

## Client Integration Pattern

### Flat Methods

The client uses flat methods named `<area>_<action>`, NOT nested accessors like `client.search_monitors.list`. Each method builds the service with the connection and calls it.

```ruby
# lib/exa/client.rb (YARD comments omitted)
def search_monitor_create(search:, webhook:, **params)
  Services::SearchMonitors::Create.new(connection, search: search, webhook: webhook, **params).call
end

def search_monitor_list(**params)
  Services::SearchMonitors::List.new(connection, **params).call
end

def search_monitor_get(id)
  Services::SearchMonitors::Get.new(connection, id: id).call
end

def search_monitor_update(id, **params)
  Services::SearchMonitors::Update.new(connection, id: id, **params).call
end

def search_monitor_delete(id)
  Services::SearchMonitors::Delete.new(connection, id: id).call
end

# A resource nested under a monitor takes the parent id first
def search_monitor_runs_list(monitor_id, **params)
  Services::SearchMonitors::RunsList.new(connection, monitor_id: monitor_id, **params).call
end

def search_monitor_runs_get(monitor_id, run_id)
  Services::SearchMonitors::RunsGet.new(connection, monitor_id: monitor_id, run_id: run_id).call
end
```

Every method has a YARD comment with `@param` and `@return` lines in the real file.

---

## CLI Command Structure

### Command Naming Pattern

Commands use kebab-case with the area as prefix:
```
search-monitor-create, search-monitor-list, search-monitor-get, search-monitor-update, search-monitor-delete
search-monitor-trigger, search-monitor-batch
search-monitor-runs-list, search-monitor-runs-get
agent-run-create, agent-run-get, agent-run-list, agent-run-cancel, agent-run-stop, agent-run-delete, agent-run-events
```

### Command File Structure

**Individual Executable Files:**
Each command is a separate executable in `exe/`:
```
exe/
├── exa-ai (main dispatcher)
├── exa-ai-search-monitor-create
├── exa-ai-search-monitor-get
├── exa-ai-search-monitor-list
├── exa-ai-agent-run-get
└── ...
```

**Main Dispatcher Pattern:**
`exe/exa-ai` lists each command in `AVAILABLE_COMMANDS` (for help text) and `exec`s the matching file:
```ruby
# exe/exa-ai
module ExaCLI
  AVAILABLE_COMMANDS = {
    "search" => "Search the web",
    # ...
    "search-monitor-get" => "Get search monitor details",
    # ...
  }.freeze

  def self.run
    case ARGV[0]
    # ...
    when "search-monitor-get"
      exec File.expand_path("../exa-ai-search-monitor-get", __FILE__), *ARGV[1..]
    # ...
    end
  end
end
```

### Command Implementation Pattern

**Simple Commands (get, delete):** `exe/exa-ai-search-monitor-get`
```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "exa-ai"

api_key = nil
output_format = "json"
monitor_id = nil

args = ARGV.dup
while args.any?
  arg = args.shift
  case arg
  when "--api-key"
    api_key = args.shift
  when "--output-format"
    output_format = args.shift
  when "--help", "-h"
    puts <<~HELP
      Usage: exa-ai search-monitor-get ID [options]
      # ... help text
    HELP
    exit 0
  else
    if arg.start_with?("-") || monitor_id
      warn "Unknown option: #{arg}"
      exit 1
    end
    monitor_id = arg
  end
end

unless monitor_id
  warn "Error: ID is required. Run with --help for usage."
  exit 1
end

begin
  output_format = Exa::CLI::Base.resolve_output_format(output_format)
  client = Exa::CLI::Base.build_client(Exa::CLI::Base.resolve_api_key(api_key))
  result = client.search_monitor_get(monitor_id)
  puts Exa::CLI::Formatters::SearchMonitorFormatter.format(result, output_format)
rescue Exa::Unauthorized => e
  # ... error handling, see "CLI Error Handling Pattern"
end
```

**Commands with many options (create):** `exe/exa-ai-search-monitor-create` collects options into a `search` hash, a `webhook` hash and a `params` hash. It uses `Exa::CLI::Base` helpers for typed values:
```ruby
search[:num_results] = Exa::CLI::Base.parse_integer("--num-results", args.shift)
search[:include_domains] = Exa::CLI::Base.option_value("--include-domains", args.shift).split(",").map(&:strip)
params[:output_schema] = Exa::CLI::Base.parse_json_or_file("--output-schema", args.shift)
```
Then it checks required values and calls the client:
```ruby
unless search[:query] && webhook[:url]
  warn "Error: --query and --webhook-url are required. Run with --help for usage."
  exit 1
end

# ...
result = client.search_monitor_create(search: search, webhook: webhook, **params)
puts Exa::CLI::Formatters::SearchMonitorFormatter.format(result, output_format)
```

### CLI Helpers

**`Exa::CLI::Base` (`lib/exa/cli/base.rb`) provides:**
- `resolve_api_key(flag_value)` - Get API key from flag or ENV, raises `Exa::ConfigurationError` if missing
- `resolve_output_format(flag_value)` - Validate format (json, pretty, text, toon)
- `build_client(api_key, **options)` - Create client instance
- `option_value`, `text_value`, `parse_integer`, `parse_json_or_file` - Parse option values (JSON options accept `@file.json`)
- `reject_unknown_option(arg)` - Stop on an unknown `--flag`

**Formatters** are in `lib/exa/cli/formatters/`: `SearchMonitorFormatter`, `AgentRunFormatter`, `SearchFormatter`, `AnswerFormatter`, `ContentsFormatter`, `ContextFormatter`. Each has `self.format(result, format)`. `SearchMonitorFormatter` handles monitors, runs, lists and batch results in one class.

---

## Datetime Handling

### No Parsing in Resources

**Finding:** Resources do NOT parse datetime strings. They store them as-is from the API.

```ruby
# In the resource (lib/exa/resources/search_monitor.rb), from_response:
new(
  # ...
  next_run_at: body["nextRunAt"],  # String from API
  created_at: body["createdAt"],   # String from API
  updated_at: body["updatedAt"],   # String from API
  # ...
)
```
There is no `Time.parse` or `DateTime` conversion anywhere in the resource.

**Datetime fields in API responses:**
```json
{
  "createdAt": "2023-11-07T05:31:56Z",
  "updatedAt": "2023-11-07T05:31:56Z"
}
```

---

## Test Patterns

### Test File Organization

Tests mirror the lib structure:
```
test/
├── test_helper.rb
├── services/
│   └── search_monitors/
│       ├── create_test.rb
│       ├── get_test.rb
│       ├── list_test.rb
│       └── ...
├── resources/
│   └── (resource tests, e.g. agent_run_test.rb)
├── cli/
│   └── (CLI and formatter tests)
└── integration/
    └── search_monitors_integration_test.rb
```

### Service Test Pattern

**Structure** (`test/services/search_monitors/get_test.rb`):
```ruby
require "test_helper"

class SearchMonitorsGetTest < Minitest::Test
  def test_call_gets_monitor
    stub_request(:get, "https://api.exa.ai/monitors/mon_abc123")
      .to_return(
        status: 200,
        body: { id: "mon_abc123", status: "disabled", outputSchema: { type: "object" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    connection = Exa::Connection.build(api_key: "test_key")

    result = Exa::Services::SearchMonitors::Get.new(connection, id: "mon_abc123").call

    assert_requested :get, "https://api.exa.ai/monitors/mon_abc123"
    assert_equal "mon_abc123", result.id
    assert result.disabled?
    assert_equal({ "type" => "object" }, result.output_schema)
  end

  def test_call_raises_not_found_on_404
    stub_request(:get, "https://api.exa.ai/monitors/mon_missing")
      .to_return(status: 404, body: { error: "Not found" }.to_json, headers: { "Content-Type" => "application/json" })
    connection = Exa::Connection.build(api_key: "test_key")

    assert_raises(Exa::NotFound) do
      Exa::Services::SearchMonitors::Get.new(connection, id: "mon_missing").call
    end
  end
end
```

### Test Helper Setup

**`test/test_helper.rb` provides:**
- WebMock configuration (real network connections are blocked)
- VCR configuration for integration tests
- `skip_unless_integration_enabled` - skips a test unless `RUN_INTEGRATION_TESTS=true`
- `with_api_key(api_key)` - sets `ENV["EXA_API_KEY"]` for a block
- `with_debug_logging` - sets `EXA_DEBUG` for a block
- `run_exe_in_process(name, *argv)` - runs a file from `exe/` inside the test process so WebMock stubs apply; returns `[stdout, stderr, exit_status]`

A test that defines `setup` or `teardown` calls `super` first, as `SearchMonitorsIntegrationTest#setup` does.

**WebMock is used for unit tests:**
- `stub_request(:post, url).with(body: ...).to_return(status: ..., body: ...)`
- `assert_requested :post, url`

**VCR is used for integration tests:**
- Records real HTTP interactions (`VCR.use_cassette("search_monitor_lifecycle") { ... }`)
- Replays them in future test runs
- Filters sensitive data (`<EXA_API_KEY>`)

### Common Assertions

```ruby
# Type checking
assert_instance_of Exa::Resources::SearchMonitor, monitor

# Field values
assert_equal expected, result.field
refute_nil result.field
assert_nil monitor.trigger

# Status helpers
assert result.disabled?
refute result.active?

# Error handling
assert_raises(Exa::NotFound) do
  service.call
end
```

---

## Error Handling

### Exception Hierarchy

```ruby
# lib/exa/error.rb
class Error < StandardError
  attr_reader :response

  def initialize(message = nil, response = nil)
    @response = response
    super(message)
  end
end

# Client errors (4xx)
class ClientError < Error; end
class BadRequest < ClientError; end          # 400
class Unauthorized < ClientError; end        # 401
class PaymentRequired < ClientError; end     # 402
class Forbidden < ClientError; end           # 403
class NotFound < ClientError; end            # 404
class UnprocessableEntity < ClientError; end # 422
class TooManyRequests < ClientError; end     # 429

# Server errors (5xx)
class ServerError < Error; end
class InternalServerError < ServerError; end # 500
class BadGateway < ServerError; end          # 502
class ServiceUnavailable < ServerError; end  # 503
class GatewayTimeout < ServerError; end      # 504

# Configuration errors
class ConfigurationError < Error; end
```

### HTTP Status Code Mapping

`Exa::Middleware::RaiseError` (`lib/exa/middleware/raise_error.rb`) maps status codes to exceptions. Services don't need to handle this explicitly. Any other 4xx raises `ClientError`, any other 5xx raises `ServerError`.

### CLI Error Handling Pattern

From `exe/exa-ai-search-monitor-get`:
```ruby
begin
  # ... command execution
rescue Exa::Unauthorized => e
  warn "Authentication failed: #{e.message}"
  warn "Please provide a valid API key via --api-key or EXA_API_KEY environment variable"
  exit 1
rescue Exa::ClientError => e
  warn "Client error: #{e.message}"
  exit 1
rescue Exa::ServerError => e
  warn "Server error: #{e.message}"
  exit 1
rescue Exa::Error => e
  warn "Error: #{e.message}"
  exit 1
rescue StandardError => e
  warn "Unexpected error: #{e.message}"
  exit 1
end
```

---

## References

**Key Files:**
- `lib/exa/client.rb` - Client integration pattern
- `lib/exa/services/search_monitors/get.rb` - Service pattern
- `lib/exa/services/search_monitors/create.rb` - Service that reshapes the request body
- `lib/exa/services/search_monitors/list.rb` - List service pattern
- `lib/exa/resources/search_monitor.rb` - Resource pattern
- `lib/exa/resources/search_monitor_list.rb` - Paginated collection
- `test/services/search_monitors/get_test.rb` - Test pattern
- `test/integration/search_monitors_integration_test.rb` - Integration test pattern
- `exe/exa-ai-search-monitor-create` - Command with many options
- `exe/exa-ai-search-monitor-get` - Simple CLI command
- `lib/exa/cli/base.rb` - CLI helpers
- `lib/exa/error.rb` - Error hierarchy
