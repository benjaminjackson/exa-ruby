# Phase 1 Context Findings: Imports Implementation

**Date:** 2025-11-23
**Branch:** feature/webset-imports
**Purpose:** Document existing codebase patterns to guide imports implementation

## Table of Contents

1. [Service Object Pattern](#service-object-pattern)
2. [Resource Object Pattern](#resource-object-pattern)
3. [List and Pagination Handling](#list-and-pagination-handling)
4. [Client Integration Pattern](#client-integration-pattern)
5. [CLI Command Structure](#cli-command-structure)
6. [Datetime Handling](#datetime-handling)
7. [Test Patterns](#test-patterns)
8. [Error Handling](#error-handling)
9. [Key Insights for Imports](#key-insights-for-imports)

---

## Service Object Pattern

### Location Pattern
Services are organized under `lib/exa/services/websets/`:
```
lib/exa/services/websets/
├── create_search.rb
├── get_search.rb
├── cancel_search.rb
├── create_enrichment.rb
├── retrieve_enrichment.rb
├── update_enrichment.rb
├── delete_enrichment.rb
├── cancel_enrichment.rb
├── list.rb
├── retrieve.rb
├── update.rb
├── delete.rb
└── cancel.rb
```

### Implementation Pattern

**Basic Structure:**
```ruby
module Exa
  module Services
    module Websets
      class CreateSearch
        def initialize(connection, webset_id:, **params)
          @connection = connection
          @webset_id = webset_id
          @params = params
        end

        def call
          response = @connection.post(
            "/websets/v0/websets/#{@webset_id}/searches",
            @params
          )
          body = response.body

          Resources::WebsetSearch.new(
            id: body["id"],
            object: body["object"],
            # ... map all fields from API response
          )
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
- Returns a Resource object (NOT raw Faraday response)
- Direct instantiation of resource with API response fields
- No base class inheritance (simple, standalone classes)

**Validation:**
Some services include validators (e.g., `CreateSearchValidator.validate!(@params)`), but not all. Validators are separate classes in the same directory.

---

## Resource Object Pattern

### Location Pattern
Resources are in `lib/exa/resources/`:
```
lib/exa/resources/
├── webset.rb
├── webset_collection.rb
├── webset_search.rb
├── webset_enrichment.rb
├── webset_enrichment_collection.rb
└── ... (other resources)
```

### Implementation Pattern

**Frozen Struct with Keyword Init:**
```ruby
module Exa
  module Resources
    class WebsetSearch < Struct.new(
      :id,
      :object,
      :status,
      :webset_id,
      :query,
      :entity,
      :criteria,
      :count,
      :behavior,
      :exclude,
      :scope,
      :progress,
      :recall,
      :metadata,
      :canceled_at,
      :canceled_reason,
      :created_at,
      :updated_at,
      keyword_init: true
    )
      def initialize(
        id:,
        object:,
        status:,
        webset_id: nil,
        query: nil,
        # ... all other fields with defaults
      )
        super
        freeze  # Make immutable
      end

      # Helper methods for status checks
      def created?
        status == "created"
      end

      def running?
        status == "running"
      end

      # Serialization method
      def to_h
        {
          id: id,
          object: object,
          status: status,
          # ... all fields
        }.compact  # Remove nil values
      end
    end
  end
end
```

**Key Characteristics:**
- Use `Struct.new` with `keyword_init: true`
- Explicit `initialize` method with all fields
- Call `freeze` at end of initialize for immutability
- Helper methods for common checks (status?, completed?, etc.)
- `#to_h` method that returns compact hash (removes nil values)
- No datetime parsing - strings are kept as-is from API

**Helper Methods Pattern:**
Resources include convenience methods for status checks:
```ruby
def pending?
  status == "pending"
end

def completed?
  status == "completed"
end
```

---

## List and Pagination Handling

### Two Types of Collections

**1. Paginated Collections (with cursor pagination):**

```ruby
# lib/exa/resources/webset_collection.rb
class WebsetCollection < Struct.new(
  :data,
  :has_more,
  :next_cursor,
  keyword_init: true
)
  def initialize(data:, has_more: false, next_cursor: nil)
    super
    freeze
  end

  def empty?
    data.empty?
  end

  def to_h
    {
      data: data,
      has_more: has_more,
      next_cursor: next_cursor
    }
  end
end
```

**API Response Structure:**
```json
{
  "data": [...],
  "hasMore": true,
  "nextCursor": "cursor_abc"
}
```

**2. Simple Collections (no pagination):**

```ruby
# lib/exa/resources/webset_enrichment_collection.rb
class WebsetEnrichmentCollection < Struct.new(
  :data,
  keyword_init: true
)
  def initialize(data:)
    super
    freeze
  end

  def empty?
    data.empty?
  end

  def to_h
    { data: data }
  end
end
```

### Service Implementation for Lists

```ruby
# lib/exa/services/websets/list.rb
class List
  def initialize(connection, **params)
    @connection = connection
    @params = params
  end

  def call
    response = @connection.get("/websets/v0/websets", @params)
    body = response.body

    Resources::WebsetCollection.new(
      data: body["data"],
      has_more: body["hasMore"],
      next_cursor: body["nextCursor"]
    )
  end
end
```

**Key Decision for Imports:**
Need to determine if imports list endpoint returns:
- Paginated collection (like websets list)
- Simple array (like enrichments list)
- Or the full resource in the `data` array

---

## Client Integration Pattern

### Current Pattern: Direct Methods

**No Nested Accessors:**
The client uses flat methods, NOT nested accessors like `client.websets.imports.list`.

```ruby
# lib/exa/client.rb
class Client
  # Webset methods
  def list_websets(**params)
    Services::Websets::List.new(connection, **params).call
  end

  def get_webset(id, **params)
    Services::Websets::Retrieve.new(connection, id: id, **params).call
  end

  # Webset search methods (note: flat, not nested)
  def create_webset_search(webset_id:, **params)
    Services::Websets::CreateSearch.new(connection, webset_id: webset_id, **params).call
  end

  def get_webset_search(webset_id:, id:)
    Services::Websets::GetSearch.new(connection, webset_id: webset_id, id: id).call
  end

  # Enrichment methods
  def create_enrichment(webset_id:, **params)
    Services::Websets::CreateEnrichment.new(connection, webset_id: webset_id, **params).call
  end
end
```

**Pattern for Imports:**
Based on this pattern, import methods should be:
```ruby
# NOT: client.websets.imports.create
# YES: client.create_import(**params)
# or:  client.list_imports
```

Since imports are NOT nested under specific websets in the API (`/websets/v0/imports`, not `/websets/{id}/imports`), they should follow the flat pattern:

```ruby
def list_imports(**params)
  Services::Websets::Imports::List.new(connection, **params).call
end

def create_import(**params)
  Services::Websets::Imports::Create.new(connection, **params).call
end

def get_import(id)
  Services::Websets::Imports::Get.new(connection, id: id).call
end

def update_import(id, **params)
  Services::Websets::Imports::Update.new(connection, id: id, **params).call
end

def delete_import(id)
  Services::Websets::Imports::Delete.new(connection, id: id).call
end
```

---

## CLI Command Structure

### Command Naming Pattern

Commands use kebab-case with prefixes:
```
webset-create, webset-list, webset-get, webset-update, webset-delete
webset-search-create, webset-search-get, webset-search-cancel
webset-item-list, webset-item-get, webset-item-delete
enrichment-create, enrichment-list, enrichment-get, enrichment-update, enrichment-delete
```

**For imports, this suggests:**
```
webset-import-create
webset-import-list
webset-import-get
webset-import-update
webset-import-delete
```

### Command File Structure

**Individual Executable Files:**
Each command is a separate executable in `exe/`:
```
exe/
├── exa-ai (main dispatcher)
├── exa-ai-enrichment-create
├── exa-ai-enrichment-list
├── exa-ai-webset-list
└── ...
```

**Main Dispatcher Pattern:**
```ruby
# exe/exa-ai
case ARGV[0]
when "enrichment-create"
  exec File.expand_path("../exa-ai-enrichment-create", __FILE__), *ARGV[1..]
when "enrichment-list"
  exec File.expand_path("../exa-ai-enrichment-list", __FILE__), *ARGV[1..]
# ...
end
```

### Command Implementation Pattern

**Simple Commands (list, get):**
```ruby
#!/usr/bin/env ruby
require "exa-ai"

# Parse arguments (simple manual parsing)
webset_id = nil
api_key = nil
output_format = "json"

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
      Usage: exa-ai enrichment-list <webset_id> [OPTIONS]
      # ... help text
    HELP
    exit 0
  else
    webset_id = arg if webset_id.nil?
  end
end

# Validate required args
if webset_id.nil?
  $stderr.puts "Error: webset_id argument is required"
  exit 1
end

# Execute
begin
  api_key = Exa::CLI::Base.resolve_api_key(api_key)
  output_format = Exa::CLI::Base.resolve_output_format(output_format)
  client = Exa::CLI::Base.build_client(api_key)

  # Call client method
  result = client.some_method(...)

  # Format and output
  output = Exa::CLI::Formatters::SomeFormatter.format(result, output_format)
  puts output

rescue Exa::Unauthorized => e
  $stderr.puts "Authentication error: #{e.message}"
  exit 1
# ... other error handling
end
```

**Complex Commands (create with many params):**
```ruby
#!/usr/bin/env ruby
require "exa-ai"

# Helper for JSON parsing (supports @file.json syntax)
def parse_json_or_file(value)
  json_data = if value.start_with?("@")
                file_path = value[1..]
                JSON.parse(File.read(file_path))
              else
                JSON.parse(value)
              end
  deep_symbolize_keys(json_data)
end

def parse_args(argv)
  args = { output_format: "json", api_key: nil }

  # ... parsing logic with while loop

  args
end

# Main execution with validation
args = parse_args(ARGV)

unless args[:required_param]
  $stderr.puts "Error: --required-param is required"
  exit 1
end

# ... execute command
```

### CLI Helpers

**`Exa::CLI::Base` provides:**
- `resolve_api_key(flag_value)` - Get API key from flag or ENV
- `resolve_output_format(flag_value)` - Validate format
- `build_client(api_key, **options)` - Create client instance

**Formatters exist for:**
- WebsetFormatter (`format`, `format_collection`)
- EnrichmentFormatter (`format`, `format_collection`)
- WebsetItemFormatter
- (Will need ImportFormatter)

---

## Datetime Handling

### No Parsing in Resources

**Finding:** Resources do NOT parse datetime strings. They store them as-is from the API.

```ruby
# In service:
Resources::WebsetSearch.new(
  created_at: body["createdAt"],  # String from API
  updated_at: body["updatedAt"]   # String from API
)

# In resource:
class WebsetSearch < Struct.new(:created_at, :updated_at, ...)
  # No Time.parse or DateTime conversion
end
```

**Datetime fields in API responses:**
```json
{
  "createdAt": "2023-11-07T05:31:56Z",
  "updatedAt": "2023-11-07T05:31:56Z"
}
```

**Pattern for Imports:**
Import resources should store datetime strings directly:
```ruby
Resources::Import.new(
  created_at: body["createdAt"],        # Keep as string
  updated_at: body["updatedAt"],        # Keep as string
  failed_at: body["failedAt"],          # Keep as string
  upload_valid_until: body["uploadValidUntil"]  # Keep as string
)
```

---

## Test Patterns

### Test File Organization

Tests mirror the lib structure:
```
test/
├── test_helper.rb
├── services/
│   └── websets/
│       ├── create_search_test.rb
│       ├── list_test.rb
│       └── ...
├── resources/
│   └── (resource tests if needed)
└── integration/
    └── (integration tests)
```

### Service Test Pattern

**Structure:**
```ruby
require "test_helper"

module Exa
  module Services
    module Websets
      class CreateSearchTest < Minitest::Test
        def setup
          @connection = Exa::Connection.build(api_key: "test_key")
          @webset_id = "ws_abc123"
        end

        def test_call_creates_search_with_minimal_params
          # Stub HTTP request
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches")
            .with(
              body: {
                query: "AI startups",
                count: 5
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                id: "search_xyz789",
                object: "webset_search",
                status: "created",
                # ... API response
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          # Create service and call
          service = CreateSearch.new(
            @connection,
            webset_id: @webset_id,
            query: "AI startups",
            count: 5
          )
          result = service.call

          # Assertions
          assert_instance_of Exa::Resources::WebsetSearch, result
          assert_equal "search_xyz789", result.id
          assert_equal "created", result.status
        end

        def test_call_raises_unauthorized_on_401
          stub_request(:post, "https://api.exa.ai/websets/v0/websets/#{@webset_id}/searches")
            .to_return(
              status: 401,
              body: { error: "Invalid API key" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateSearch.new(@connection, webset_id: @webset_id, query: "test")

          assert_raises(Exa::Unauthorized) do
            service.call
          end
        end
      end
    end
  end
end
```

### Test Helper Setup

**`test/test_helper.rb` provides:**
- WebMock configuration
- VCR configuration for integration tests
- Test helpers (`with_api_key`, `wait_for_webset_completion`)
- WebsetsCleanupHelper module for integration test cleanup

**WebMock is used for unit tests:**
- `stub_request(:post, url).with(body: ...).to_return(status: ..., body: ...)`
- `assert_requested :post, url`

**VCR is used for integration tests:**
- Records real HTTP interactions
- Replays them in future test runs
- Filters sensitive data (`<EXA_API_KEY>`)

### Common Assertions

```ruby
# Type checking
assert_instance_of Exa::Resources::WebsetSearch, result

# Field values
assert_equal expected, result.field
refute_nil result.field

# Collections
assert_equal 2, result.criteria.length
refute_empty result.data

# Status helpers
assert result.created?
refute result.running?

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

The Faraday middleware automatically maps status codes to exceptions. Services don't need to handle this explicitly.

**Expected errors for import operations:**
- 401 Unauthorized - Invalid API key
- 404 NotFound - Import not found
- 400 BadRequest - Invalid parameters
- 422 UnprocessableEntity - Validation errors
- 500 InternalServerError - Server issues

### CLI Error Handling Pattern

```ruby
begin
  # ... command execution
rescue Exa::ConfigurationError => e
  $stderr.puts "Configuration error: #{e.message}"
  exit 1
rescue Exa::Unauthorized => e
  $stderr.puts "Authentication error: #{e.message}"
  $stderr.puts "Check your API key (set EXA_API_KEY or use --api-key)"
  exit 1
rescue Exa::ClientError => e
  $stderr.puts "Client error: #{e.message}"
  exit 1
rescue Exa::ServerError => e
  $stderr.puts "Server error: #{e.message}"
  exit 1
rescue Exa::Error => e
  $stderr.puts "Error: #{e.message}"
  exit 1
rescue StandardError => e
  $stderr.puts "Unexpected error: #{e.message}"
  exit 1
end
```

---

## Key Insights for Imports

### 1. Service Organization

Create services under `lib/exa/services/websets/imports/`:
```
lib/exa/services/websets/imports/
├── create.rb
├── list.rb
├── get.rb
├── update.rb
└── delete.rb
```

Each service follows the standard pattern:
- Constructor: `initialize(connection, id: nil, **params)`
- Single method: `#call`
- Returns: `Resources::Import` object

### 2. Resource Structure

Create `lib/exa/resources/import.rb`:
```ruby
class Import < Struct.new(
  :id,
  :object,
  :status,
  :format,
  :entity,
  :title,
  :count,
  :metadata,
  :failed_reason,
  :failed_at,
  :failed_message,
  :created_at,
  :updated_at,
  :upload_url,
  :upload_valid_until,
  keyword_init: true
)
  def initialize(...)
    super
    freeze
  end

  def pending?
    status == "pending"
  end

  def to_h
    # ... all fields
  end
end
```

### 3. List Response Handling

**Critical Question:** What does the list imports API return?

Based on patterns:
- If paginated → Create `ImportCollection` with `data`, `has_more`, `next_cursor`
- If simple array → Create `ImportCollection` with just `data`
- If nested in response → Unwrap appropriately

**Most likely (based on websets list pattern):**
```ruby
# GET /websets/v0/imports returns:
{
  "data": [...],
  "hasMore": true,
  "nextCursor": "..."
}

# So create:
class ImportCollection < Struct.new(:data, :has_more, :next_cursor, keyword_init: true)
```

### 4. Client Methods

Add to `lib/exa/client.rb`:
```ruby
def list_imports(**params)
  Services::Websets::Imports::List.new(connection, **params).call
end

def create_import(**params)
  Services::Websets::Imports::Create.new(connection, **params).call
end

def get_import(id)
  Services::Websets::Imports::Get.new(connection, id: id).call
end

def update_import(id, **params)
  Services::Websets::Imports::Update.new(connection, id: id, **params).call
end

def delete_import(id)
  Services::Websets::Imports::Delete.new(connection, id: id).call
end
```

### 5. CLI Commands

Create files:
```
exe/exa-ai-webset-import-create
exe/exa-ai-webset-import-list
exe/exa-ai-webset-import-get
exe/exa-ai-webset-import-update
exe/exa-ai-webset-import-delete
```

Add to main dispatcher (`exe/exa-ai`):
```ruby
when "webset-import-create"
  exec File.expand_path("../exa-ai-webset-import-create", __FILE__), *ARGV[1..]
when "webset-import-list"
  exec File.expand_path("../exa-ai-webset-import-list", __FILE__), *ARGV[1..]
# ...
```

Create formatter: `lib/exa/cli/formatters/import_formatter.rb`

### 6. Testing Strategy

**Unit tests:**
```
test/services/websets/imports/
├── create_test.rb
├── list_test.rb
├── get_test.rb
├── update_test.rb
└── delete_test.rb
```

**Resource tests (if needed):**
```
test/resources/import_test.rb
```

**Integration tests:**
```
test/integration/websets/imports_integration_test.rb
```

**VCR cassettes:**
```
test/vcr_cassettes/imports/
├── create_import.yml
├── list_imports.yml
├── get_import.yml
├── update_import.yml
└── delete_import.yml
```

### 7. No Datetime Parsing Needed

Keep datetime fields as strings:
- `created_at`, `updated_at`, `failed_at`, `upload_valid_until` all stay as ISO 8601 strings
- No `Time.parse` or conversion required
- Matches existing codebase pattern

### 8. Status Helper Methods

Based on API spec, add helpers to Import resource:
```ruby
def pending?
  status == "pending"
end

def processing?
  status == "processing"
end

def completed?
  status == "completed"
end

def failed?
  status == "failed"
end
```

---

## Questions to Resolve Before Implementation

1. **List API Response Structure:**
   - Does `GET /websets/v0/imports` return paginated results with `hasMore`/`nextCursor`?
   - Or is it a simple array?
   - This affects whether we need `ImportCollection` with pagination support

2. **Status Values:**
   - What are all possible values for `status`? (only "pending" shown in spec)
   - Should we add helper methods for all status values?

3. **Failed Reason Values:**
   - What are all possible values for `failedReason`? (only "invalid_format" shown)

4. **Entity Types:**
   - Currently only "company" is documented. Are there others?

5. **Format Types:**
   - Currently only "csv" is documented. Are there others?

6. **Upload Workflow:**
   - What's the complete workflow for using `uploadUrl`?
   - Is file upload a separate operation we need to support?

---

## Next Steps (Phase 2)

1. **Resolve Questions:** Get answers from API documentation or testing
2. **Define Resource:** Create `Import` resource with all 14 fields
3. **Implement Services:** Follow TDD for all 5 CRUD operations
4. **Wire Client:** Add methods to Client class
5. **Build CLI:** Create 5 command files and update dispatcher
6. **Test:** Write comprehensive unit and integration tests

---

## References

**Key Files Examined:**
- `lib/exa/client.rb` - Client integration pattern
- `lib/exa/services/websets/create_search.rb` - Service pattern
- `lib/exa/services/websets/list.rb` - List service pattern
- `lib/exa/resources/webset_search.rb` - Resource pattern
- `lib/exa/resources/webset_collection.rb` - Paginated collection
- `lib/exa/resources/webset_enrichment_collection.rb` - Simple collection
- `test/services/websets/create_search_test.rb` - Test pattern
- `exe/exa-ai-enrichment-create` - Complex CLI command
- `exe/exa-ai-webset-list` - List CLI command
- `lib/exa/cli/base.rb` - CLI helpers
- `lib/exa/error.rb` - Error hierarchy

**Total Files Analyzed:** 20+ service, resource, CLI, and test files
