# Exa Ruby Gem - Implementation Plan

Build the gem incrementally, verifying tests pass at each stage. Start with the absolute minimum needed for one working endpoint, then expand.

---

## Phase 0: Project Scaffolding
**Goal**: Create the gem skeleton and verify tooling works

### Tasks
1. Create gemspec file
2. Create basic directory structure
3. Set up Rakefile with test task
4. Create test_helper.rb with WebMock
5. Create lib/exa.rb entry point
6. Create lib/exa/version.rb
7. Verify `bundle install` works
8. Verify `rake test` runs (even with no tests)

**Verification**:
- `bundle install` succeeds
- `rake test` runs without errors

---

## Phase 1: Configuration Only
**Goal**: Build and test configuration system in isolation

### Tasks
1. Implement module-level configuration in lib/exa.rb
   - `Exa.configure` block
   - `Exa.api_key`, `Exa.base_url`, `Exa.timeout`
   - `Exa.reset` for test isolation
2. Write test/exa_test.rb
   - Test configuration block
   - Test default values
   - Test reset
3. Run tests, verify green

**Verification**:
```ruby
Exa.configure do |config|
  config.api_key = "test_key"
end

Exa.api_key # => "test_key"
Exa.reset
Exa.api_key # => nil
```

---

## Phase 2: Error Hierarchy
**Goal**: Define all error classes before implementing HTTP logic

### Tasks
1. Create lib/exa/error.rb with full hierarchy
   - Base Error with response attribute
   - ClientError subclasses (400, 401, 403, 404, 422, 429)
   - ServerError subclasses (500, 502, 503, 504)
   - ConfigurationError
2. Write test/error_test.rb
   - Test error initialization with message and response
   - Test error hierarchy

**Verification**:
```ruby
error = Exa::Unauthorized.new("Bad token", { status: 401 })
error.message # => "Bad token"
error.response # => { status: 401 }
error.is_a?(Exa::ClientError) # => true
error.is_a?(Exa::Error) # => true
```

---

## Phase 3: Connection Builder
**Goal**: Build Faraday connection with proper middleware stack

### Tasks
1. Create lib/exa/connection.rb
   - `Connection.build` class method
   - Takes api_key and options hash
   - Configures Faraday with:
     - Authorization header
     - JSON request/response
     - Timeouts
     - Adapter (overridable for tests)
2. Create lib/exa/middleware/raise_error.rb
   - Maps HTTP status codes to exception classes
   - Extracts error message from response body
3. Write test/connection_test.rb
   - Test connection is Faraday::Connection
   - Test authorization header is set
   - Test timeout options
   - Test custom adapter can be passed
4. Write test/middleware/raise_error_test.rb
   - Test each status code maps to correct exception
   - Test error message extraction

**Verification**:
```ruby
conn = Exa::Connection.build(api_key: "test", timeout: 5)
conn.is_a?(Faraday::Connection) # => true
# Stub a 401 response, verify it raises Unauthorized
```

---

## Phase 4: First Resource Object (SearchResult)
**Goal**: Create one resource object using frozen Struct

### Tasks
1. Create lib/exa/resources/search_result.rb
   - Define SearchResult using Struct with keyword_init and freeze
   - Fields: results (array), autoprompt_string (string or nil)
   - Helper methods: `#empty?`, `#first`, `#to_h`
2. Write test/resources/search_result_test.rb
   - Test initialization
   - Test immutability (attempting to modify raises error)
   - Test helper methods

**Verification**:
```ruby
result = Exa::Resources::SearchResult.new(
  results: [{ title: "Test", url: "http://example.com" }],
  autoprompt_string: nil
)
result.results.size # => 1
result.first # => { title: "Test", ... }
result.empty? # => false
```

---

## Phase 5: First Service Object (Search)
**Goal**: Implement Search service with full TDD

### Tasks
1. Create test/services/search_test.rb FIRST
   - Stub HTTP POST to /search
   - Test successful search returns SearchResult
   - Test query parameter is sent
   - Test 401 raises Unauthorized
   - Test 500 raises ServerError
2. Create lib/exa/services/search.rb
   - Initialize with connection and params
   - `#call` method posts to /search endpoint
   - Returns SearchResult resource
3. Run tests until green

**Verification**:
```ruby
# In test - stub the HTTP call
stub_request(:post, "https://api.exa.ai/search")
  .with(body: { query: "test" })
  .to_return(status: 200, body: { results: [], autoprompt_string: nil }.to_json)

conn = Exa::Connection.build(api_key: "test")
service = Exa::Services::Search.new(conn, query: "test")
result = service.call

result.is_a?(Exa::Resources::SearchResult) # => true
```

---

## Phase 6: Client Interface
**Goal**: Wire everything together in Client class

### Tasks
1. Create lib/exa/client.rb
   - Initialize with api_key and options
   - Builds connection internally
   - `#search` method delegates to Search service
2. Write test/client_test.rb
   - Test client initialization
   - Test client.search calls service and returns result
   - Test missing api_key raises ConfigurationError
3. Update lib/exa.rb to require all files
4. Run full test suite

**Verification**:
```ruby
client = Exa::Client.new(api_key: "test")
result = client.search("ruby programming")
result.is_a?(Exa::Resources::SearchResult) # => true
```

---

## Phase 7: First Integration Test
**Goal**: Verify end-to-end with VCR cassette

### Tasks
1. Add VCR configuration to test_helper.rb
2. Create test/integration/search_integration_test.rb
   - Use VCR cassette
   - Make real API call (or record it)
   - Verify actual response structure
3. Run integration test, verify it passes

**Verification**:
- Integration test passes with recorded cassette
- Can replay without hitting API

---

## Phase 8: Additional Endpoints
**Goal**: Implement remaining endpoints following established patterns

### 8a. FindSimilar and GetContents Endpoints
These follow the same pattern as Search. For each:
1. Define resource object using frozen Struct
2. Write service test with stubbed HTTP responses
3. Implement service with #call method
4. Add method to Client class
5. Write integration test with VCR cassette
6. Verify all tests pass

---

### 8b. Answer Endpoint
**Endpoint**: POST /answer
**Reference**: spec/endpoints/answer.yaml

**Resource Object** - `lib/exa/resources/answer.rb`
```ruby
module Exa
  module Resources
    class Answer < Struct.new(:answer, :citations, keyword_init: true)
      def initialize(**)
        super
        freeze
      end

      def to_h
        { answer: answer, citations: citations }
      end
    end
  end
end
```

**Implementation Pattern**:
1. Create test/resources/answer_test.rb
   - Test initialization with answer and citations array
   - Test immutability
2. Create test/services/answer_test.rb
   - Stub POST to /answer
   - Test request body includes query and search_type parameters
   - Test successful response returns Answer resource
   - Test error handling (401, 500, etc.)
3. Create lib/exa/services/answer.rb
   - Initialize with connection and params (query, search_type, num_results, etc.)
   - POST to /answer endpoint
   - Return Answer resource
4. Add to Client: `def answer(**params)` method
5. Create test/integration/answer_integration_test.rb

---

### 8c. Research Start Endpoint
**Endpoint**: POST /research/v1
**Reference**: spec/endpoints/research_v1.yaml
**Note**: Creates async task, returns immediately with task ID

**Resource Objects** - `lib/exa/resources/research_task.rb`

Define a single `ResearchTask` resource that handles all status states (pending, running, completed, canceled, failed):

```ruby
module Exa
  module Resources
    class ResearchTask < Struct.new(
      :research_id, :created_at, :status, :model, :instructions,
      :output_schema, :events, :output, :cost_dollars, :finished_at,
      :error, keyword_init: true
    )
      def initialize(**)
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
        to_h_result = {
          research_id: research_id,
          created_at: created_at,
          status: status,
          model: model,
          instructions: instructions
        }
        # Include optional fields based on status
        to_h_result[:output_schema] = output_schema if output_schema
        to_h_result[:events] = events if events
        to_h_result[:output] = output if output
        to_h_result[:cost_dollars] = cost_dollars if cost_dollars
        to_h_result[:finished_at] = finished_at if finished_at
        to_h_result[:error] = error if error
        to_h_result
      end
    end
  end
end
```

**Implementation Pattern**:
1. Create test/resources/research_task_test.rb
   - Test initialization with all fields
   - Test status predicate methods (pending?, running?, completed?, etc.)
   - Test immutability
   - Test to_h includes only relevant fields
2. Create test/services/research_start_test.rb
   - Stub POST to /research/v1
   - Test request body includes instructions, model, output_schema, etc.
   - Test successful response returns ResearchTask with status: 'pending'
   - Test returns researchId for polling
   - Test error handling (401, 400, 500, etc.)
3. Create lib/exa/services/research_start.rb
   - Initialize with connection and params (instructions, model, output_schema)
   - POST to /research/v1 endpoint
   - Return ResearchTask resource
4. Add to Client: `def research_start(**params)` method
5. Create test/integration/research_start_integration_test.rb

---

### 8d. Research List Endpoint
**Endpoint**: GET /research/v1
**Reference**: spec/endpoints/research_v1.yaml
**Note**: Cursor-based pagination (NOT offset-based)

**Resource Object** - `lib/exa/resources/research_list.rb`

```ruby
module Exa
  module Resources
    class ResearchList < Struct.new(:data, :has_more, :next_cursor, keyword_init: true)
      def initialize(**)
        super
        freeze
      end

      def to_h
        { data: data, has_more: has_more, next_cursor: next_cursor }
      end
    end
  end
end
```

**Implementation Pattern**:
1. Create test/resources/research_list_test.rb
   - Test initialization with data array, has_more, next_cursor
   - Test immutability
   - Test to_h serialization
2. Create test/services/research_list_test.rb
   - Stub GET to /research/v1
   - Test query parameters: cursor (optional), limit (optional, default 10)
   - Test successful response returns ResearchList with array of ResearchTask objects
   - Test pagination: has_more=true, next_cursor is present for next page
   - Test pagination: has_more=false when no more results
   - Test error handling (401, 500, etc.)
3. Create lib/exa/services/research_list.rb
   - Initialize with connection and params (cursor: nil, limit: 10)
   - GET to /research/v1 endpoint with query params
   - Map response data array to ResearchTask objects
   - Return ResearchList resource
4. Add to Client: `def research_list(**params)` method (cursor: nil, limit: 10)
5. Create test/integration/research_list_integration_test.rb
   - Verify pagination works correctly
   - Test fetching first page, then next page using next_cursor

---

### 8e. Research Get Endpoint
**Endpoint**: GET /research/v1/{researchId}
**Reference**: spec/endpoints/research_v1_by_id.yaml
**Note**: Supports streaming via ?stream=true and detailed events via ?events=true

**Implementation Pattern**:
1. Create test/services/research_get_test.rb
   - Stub GET to /research/v1/{researchId}
   - Test path parameter researchId is included in URL
   - Test query parameters: stream (optional, boolean), events (optional, boolean)
   - Test response for each status:
     - pending: returns ResearchTask with minimal fields
     - running: returns ResearchTask with events array if ?events=true
     - completed: returns ResearchTask with output and cost_dollars
     - failed: returns ResearchTask with error field
     - canceled: returns ResearchTask with finished_at
   - Test error handling (401, 404, 500, etc.)
   - NOTE: Streaming support (?stream=true) can be stubbed for now; implement live streaming in Phase 11
2. Create lib/exa/services/research_get.rb
   - Initialize with connection, research_id, and params (stream: false, events: false)
   - GET to /research/v1/{researchId} endpoint with query params
   - Return ResearchTask resource
   - NOTE: For basic implementation, stream parameter is accepted but not processed
3. Add to Client: `def research_get(research_id, **params)` method
   - Args: research_id (required), stream: false, events: false
4. Create test/integration/research_get_integration_test.rb
   - Test fetching task with different statuses
   - Test with ?events=true to verify event log inclusion
   - Verify polling workflow: call research_get repeatedly until status changes

---

### Implementation Order for Phase 8

1. Answer endpoint (simpler, good warm-up)
2. FindSimilar endpoint
3. GetContents endpoint
4. Research Start (introduces async pattern)
5. Research List (introduces pagination)
6. Research Get (most complex, handles multiple states)

**After Each Endpoint**:
- Run full test suite: `bundle exec rake test`
- Verify no regressions
- Commit working code with conventional format

---

### Key Considerations

**Research Endpoints Special Cases**:
- ResearchTask resource must handle optional fields based on status
- Research Get polling pattern: client code will loop calling research_get until status changes
- Events field contains array of ResearchEventDtoClass objects (nested types) - for Phase 8, just accept as-is; detailed event parsing can be Phase 11+
- Streaming support (?stream=true) uses Server-Sent Events - stub for now, implement in Phase 11

**Testing Pagination**:
- Test cursor-based pagination by stubbing multiple pages
- Verify next_cursor is used correctly on subsequent calls
- Verify has_more flag correctly indicates more results exist

**Status-Based Testing**:
- Each Research status variant needs separate test stubs
- Verify optional fields are only present for appropriate statuses
- Test to_h method includes only populated fields

---

## Phase 9: Documentation & Polish
**Goal**: Make gem ready for release

### Tasks
1. Write comprehensive README.md
   - Installation
   - Quick start
   - All endpoints with examples
   - Error handling
   - Configuration options
2. Add inline documentation (YARD)
3. Create CHANGELOG.md
4. Verify gemspec metadata is complete
5. Run through example scenarios manually

---

## Phase 10: Release Preparation
**Goal**: Final checks before releasing

### Tasks
1. Run full test suite
2. Build gem locally: `rake build`
3. Install gem locally: `rake install`
4. Test in separate project: `gem install ./exa-0.1.0.gem`
5. Verify all examples in README work
6. Tag release in git

---

## Testing Philosophy

At each phase:
- **Write tests first** (except for scaffolding)
- **Run tests frequently** - they should always be green
- **Commit working code** - each phase should be a commit
- **Don't skip ahead** - verify current phase works before moving to next

## Success Criteria for Each Phase

- All tests pass (`rake test`)
- No warnings when loading gem
- Code follows Ruby conventions
- Test coverage is comprehensive (not 100%, but thorough)
- Documentation exists for user-facing features

---

## Quick Reference: File Creation Order

1. exa.gemspec
2. lib/exa/version.rb
3. lib/exa.rb (configuration only)
4. test/test_helper.rb
5. test/exa_test.rb
6. lib/exa/error.rb
7. test/error_test.rb
8. lib/exa/connection.rb
9. lib/exa/middleware/raise_error.rb
10. test/connection_test.rb
11. lib/exa/resources/search_result.rb
12. test/resources/search_result_test.rb
13. test/services/search_test.rb (write first!)
14. lib/exa/services/search.rb
15. lib/exa/client.rb
16. test/client_test.rb
17. test/integration/search_integration_test.rb

Each file should be created, tested, and verified before moving to the next.
