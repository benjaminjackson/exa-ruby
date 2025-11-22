# Exa Ruby Gem

Ruby client for the Exa.ai API. Follows pragmatic Ruby patterns with emphasis on TDD using Minitest.

## Architecture Overview

### Core Design Patterns

**Configuration DSL**
- `Exa.configure` block for setting API keys and options
- Module-level configuration (simple, sufficient for most use cases)
- Reset method for test isolation

**Faraday Middleware Stack**
- HTTP client built on Faraday for flexibility
- Start with built-in middleware from day 1:
  - `:authorization` - Bearer token authentication
  - `:json` - Request/response JSON encoding
  - `:raise_error` - Consistent error handling
  - `:logger` - Debug logging (conditional)
- Custom middleware only for Exa-specific concerns:
  - Custom error mapping (status codes to exception classes)
- Connection configuration with timeouts (critical for production)
- Support for custom adapters (enables test stubbing)

**Middleware Philosophy**
Built-in Faraday middleware is battle-tested and should be included from the start. Only create *custom* middleware when you need Exa-specific behavior that can't be handled by built-in middleware or service objects.

**Service Objects**
- One class per API operation (Search, FindSimilar, GetContents, etc.)
- Constructor takes configuration and parameters
- Single public `#call` method returns response object
- Keeps business logic isolated and testable

**Resource Objects**
- Wrap API responses in domain objects (SearchResult, Content, etc.)
- Use frozen Struct or plain classes with attr_reader for immutable value objects
- Provide helper methods for common operations
- Include `#to_h` for serialization

### Directory Structure

```
lib/
├── exa.rb                       # Main entry point, module-level config
├── exa/
│   ├── version.rb              # Gem version constant
│   ├── client.rb               # Main client interface
│   ├── error.rb                # Exception hierarchy (detailed)
│   ├── connection.rb           # Faraday builder with timeouts
│   ├── middleware/             # Custom middleware only
│   │   └── raise_error.rb      # Maps HTTP status to exceptions
│   ├── services/               # API operation service objects
│   │   ├── base.rb             # Shared service logic
│   │   ├── search.rb
│   │   ├── find_similar.rb
│   │   └── get_contents.rb
│   └── resources/              # Response wrapper objects
│       ├── search_result.rb    # Using frozen Struct
│       ├── similar_result.rb
│       ├── content.rb
│       └── paginated_collection.rb

test/
├── test_helper.rb              # WebMock, VCR setup
├── vcr_cassettes/              # Recorded HTTP interactions
├── exa_test.rb                 # Tests for main module
├── client_test.rb
├── connection_test.rb
├── services/                   # Service object tests
│   ├── search_test.rb
│   └── ...
└── integration/                # End-to-end tests
    └── search_integration_test.rb
```

## Development Workflow

### Starting New Feature

1. Write acceptance test (skip for now)
2. Break down into service objects needed
3. TDD each service object (red-green-refactor)
4. TDD resource objects if needed
5. Wire together in client
6. Run acceptance test

## Testing Commands

```bash
# Run all tests
bundle exec rake test

# Run specific test file (with bundle exec rake)
bundle exec rake test TEST=test/services/search_test.rb

# Run single test by name (with bundle exec rake)
bundle exec rake test TEST=test/services/search_test.rb TESTOPTS="--name '/test_search_returns_results/'"

# Run specific test file (direct ruby)
bundle exec ruby test/services/search_test.rb

# Run single test by name (direct ruby)
bundle exec ruby test/services/search_test.rb -n test_search_returns_results

# Run tests matching pattern
bundle exec rake test TEST="test/services/*_test.rb"

# Run with verbose output
bundle exec rake test TESTOPTS="-v"

# Run with simplified backtrace (recommended during development)
bundle exec rake test TESTOPTS="--pride"
```

### Spot Fix Development

When making targeted fixes to a specific feature, avoid running the full test suite repeatedly. Use single test runs to verify fixes quickly:

**During red-green-refactor cycles:**
- Use `bundle exec rake test TEST=<file> TESTOPTS="--name '/<test_name>/'"`
- This lets you iterate rapidly on a single test without waiting for the full suite
- Switch back to `bundle exec rake test` only after the test passes to check for regressions

**Example workflow:**
```bash
# Write failing test, then run just that test
bundle exec rake test TEST=test/services/websets/create_search_test.rb TESTOPTS="--name '/test_creates_search_with_criteria/'"

# Fix the code, re-run the single test
bundle exec rake test TEST=test/services/websets/create_search_test.rb TESTOPTS="--name '/test_creates_search_with_criteria/'"

# Once green, run full suite to ensure no regressions
bundle exec rake test
```

## TDD Workflow

### Red-Green-Refactor Cycle

1. **Red**: Write minimal failing test
   - Test one behavior at a time
   - Use descriptive test names: `test_search_raises_error_when_api_key_missing`
   - Arrange-Act-Assert structure

2. **Green**: Write simplest code to pass
   - Don't optimize prematurely
   - Hardcode if needed to get to green quickly
   - One assertion per test (generally)

3. **Refactor**: Improve code quality
   - Extract constants, methods, classes
   - DRY up test setup with helper methods
   - Keep tests readable over DRY

### Minitest Conventions

```ruby
# Use descriptive test names with test_ prefix
def test_search_returns_results_when_query_provided
  # Arrange
  client = Exa::Client.new(api_key: "test_key")

  # Act
  result = client.search("ruby programming")

  # Assert
  assert_instance_of Exa::Resources::SearchResult, result
  refute_empty result.items
end

# Use assertions that communicate intent
assert_equal expected, actual
assert_nil value
assert_empty collection
assert_includes collection, item
assert_raises(Exa::Error) { dangerous_operation }
assert_instance_of Class, object

# Use refute for negative assertions
refute_equal unexpected, actual
refute_nil value
refute_empty collection
```

### Test Organization

**Unit Tests** (lib/exa/services/search.rb → test/services/search_test.rb)
- Test single class in isolation
- Mock external dependencies (HTTP calls, other services)
- Fast (<1ms per test)

**Integration Tests** (test/integration/)
- Test multiple components working together
- Stub HTTP responses with WebMock or VCR
- Slower but verify contract between components

**Acceptance Tests** (optional, test/acceptance/)
- Test complete user workflows
- May hit real API (mark with `skip` by default)
- Run separately from main suite

## Anti-Patterns to Avoid

**Testing**
- Don't test implementation details (private methods)
- Don't duplicate production logic in tests
- Don't share state between tests (use setup/teardown)
- Don't test framework code (Faraday internals)

**Architecture**
- Don't put business logic in client class
- Don't tightly couple services to HTTP implementation
- Don't use global state beyond configuration
- Don't return raw Faraday responses (wrap in resources)
- Don't build middleware before you need it (start with service object logic, extract when duplication emerges)

**Test Data**
- Use realistic, domain-specific test queries with the Exa API
- Don't use placeholder or generic queries like "test search" or "base search"
- Exa's search engine needs proper, specific queries to understand context
- Example good queries: "AI/ML infrastructure startups with Series A funding", "venture-backed SaaS companies"
- Example bad queries: "Long running search", "Base search", "Test query"

## Debugging

```ruby
# Add to test_helper.rb for detailed output
Minitest::Test.make_my_diffs_pretty!

# Enable Faraday logging in tests
connection = Faraday.new do |f|
  f.response :logger, Logger.new($stdout), bodies: true
end

# Use pry for debugging
require "pry"
binding.pry  # Drops into REPL
```

## Dependencies Philosophy

- Prefer stdlib when sufficient
- Use Faraday for HTTP (battle-tested, flexible)
- Require Ruby 3.0+ for modern syntax support
- Avoid heavy dependencies for simple tasks
- Pin major versions, allow minor/patch updates
- Regular dependency audits for security

## Implementation Checklist

When implementing a new API endpoint:

- [ ] **Ask for OpenAPI spec or cURL example** for the endpoint
  - Review request parameters, types, and required fields
  - Note response schema and status codes
- [ ] Define the resource object using frozen Struct or plain class
- [ ] Write service object test with stubbed HTTP response
- [ ] Implement service object with `#call` method
- [ ] Add method to Client class
- [ ] Write integration test with VCR cassette
- [ ] Verify error handling (401, 404, 500, etc.)
- [ ] Update README with usage example
- [ ] Run full test suite to ensure no regressions