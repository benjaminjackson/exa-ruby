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
**Goal**: Create one resource object using Data.define

### Tasks
1. Create lib/exa/resources/search_result.rb
   - Define SearchResult using Data.define
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
**Goal**: Repeat pattern for other endpoints

For each endpoint (FindSimilar, GetContents):
1. Define resource object
2. Write service test (TDD)
3. Implement service
4. Add to client
5. Write integration test
6. Verify all tests pass

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
