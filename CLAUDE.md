# Exa Ruby Gem

Ruby client for the Exa.ai API. Follows pragmatic Ruby patterns with emphasis on TDD using Minitest.

## Architecture Overview

### Core Design Patterns

**Configuration DSL**
- `Exa.configure` block for setting API keys and options
- Configuration stored in thread-safe singleton
- Support for multiple configuration contexts (test/production)

**Faraday Middleware Stack**
- HTTP client built on Faraday for flexibility
- Middleware for authentication, error handling, retries
- Easy to test by stubbing at middleware level
- Support for custom adapters and middleware

**Middleware Decision**
Start with minimal middleware - only extract cross-cutting concerns that apply to all requests:
- Authentication (every request needs the API key header)
- Error handling (consistent error response format across endpoints)
- Optional: Retry logic if rate limits or transient failures are common

Skip custom middleware for endpoint-specific logic - handle that in service objects. The goal is to keep service objects focused on business logic while avoiding unnecessary abstraction layers.

Built-in Faraday middleware (json request/response, logger) is sufficient for most needs. Add custom middleware only when patterns emerge across multiple endpoints.

**Service Objects**
- One class per API operation (Search, FindSimilar, GetContents, etc.)
- Constructor takes configuration and parameters
- Single public `#call` method returns response object
- Keeps business logic isolated and testable

**Resource Objects**
- Wrap API responses in domain objects (SearchResult, Content, etc.)
- Provide accessor methods and helper methods
- Immutable value objects where possible

### Directory Structure

```
lib/
├── exa.rb                    # Main entry point, configuration
├── exa/
│   ├── version.rb           # Gem version constant
│   ├── configuration.rb     # Configuration management
│   ├── client.rb            # Main client interface
│   ├── error.rb             # Custom exception classes
│   ├── connection.rb        # Faraday connection builder
│   ├── middleware/          # Faraday middleware components
│   ├── services/            # API operation service objects
│   │   ├── search.rb
│   │   ├── find_similar.rb
│   │   └── get_contents.rb
│   └── resources/           # Response wrapper objects
│       ├── search_result.rb
│       ├── content.rb
│       └── base.rb

test/
├── test_helper.rb           # Shared test setup and utilities
├── exa_test.rb              # Tests for main module
├── configuration_test.rb
├── client_test.rb
├── services/                # Service object tests
│   ├── search_test.rb
│   └── ...
└── resources/               # Resource object tests
    ├── search_result_test.rb
    └── ...
```

## Testing Commands

```bash
# Run all tests
bundle exec rake test

# Run specific test file
bundle exec ruby test/services/search_test.rb

# Run tests matching pattern
bundle exec rake test TEST="test/services/*_test.rb"

# Run single test by name
bundle exec ruby test/services/search_test.rb -n test_search_returns_results

# Run with verbose output
bundle exec rake test TESTOPTS="-v"

# Run with simplified backtrace (recommended during development)
bundle exec rake test TESTOPTS="--pride"
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

## Development Workflow

### Starting New Feature

1. Write acceptance test (skip for now)
2. Break down into service objects needed
3. TDD each service object (red-green-refactor)
4. TDD resource objects if needed
5. Wire together in client
6. Run acceptance test

### Adding New API Endpoint

```ruby
# 1. Create service object test
# test/services/new_feature_test.rb
require "test_helper"

class NewFeatureTest < Minitest::Test
  def test_calls_correct_endpoint
    # stub HTTP request, assert called with correct params
  end
end

# 2. Create service object
# lib/exa/services/new_feature.rb
module Exa
  module Services
    class NewFeature
      def initialize(connection, params = {})
        @connection = connection
        @params = params
      end

      def call
        response = @connection.post("/new-feature", @params)
        Resources::Result.new(response.body)
      end
    end
  end
end

# 3. Add to client interface
# test/client_test.rb
def test_new_feature_delegates_to_service
  # test that client.new_feature calls service
end

# 4. Wire into client
# lib/exa/client.rb
def new_feature(**params)
  Services::NewFeature.new(@connection, params).call
end
```

## Common Patterns

### Stubbing HTTP Requests

```ruby
# Use WebMock for HTTP stubbing
stub_request(:post, "https://api.exa.ai/search")
  .with(
    body: hash_including(query: "test"),
    headers: {"Authorization" => "Bearer test_key"}
  )
  .to_return(
    status: 200,
    body: {results: []}.to_json,
    headers: {"Content-Type" => "application/json"}
  )
```

### Testing Configuration

```ruby
def setup
  # Save original config
  @original_api_key = Exa.configuration.api_key
end

def teardown
  # Restore config to avoid test pollution
  Exa.configure do |config|
    config.api_key = @original_api_key
  end
end

def test_configuration
  Exa.configure do |config|
    config.api_key = "new_key"
  end

  assert_equal "new_key", Exa.configuration.api_key
end
```

### Testing Error Handling

```ruby
def test_raises_authentication_error_on_401
  stub_request(:post, "https://api.exa.ai/search")
    .to_return(status: 401, body: {error: "Unauthorized"}.to_json)

  error = assert_raises(Exa::AuthenticationError) do
    client.search("test query")
  end

  assert_equal "Unauthorized", error.message
end
```

## Code Conventions

### Ruby 3.0+ Features

```ruby
# Use keyword arguments with defaults
def initialize(api_key:, timeout: 30, retries: 3)
  @api_key = api_key
  @timeout = timeout
  @retries = retries
end

# Use endless methods for simple one-liners
def authenticated? = !api_key.nil?

# Use pattern matching for complex conditionals
case response
in {status: 200, data:}
  Success.new(data)
in {status: 400..499, error:}
  ClientError.new(error)
in {status: 500..599}
  ServerError.new
end
```

### Error Hierarchy

```ruby
# lib/exa/error.rb
module Exa
  class Error < StandardError; end

  class ConfigurationError < Error; end
  class AuthenticationError < Error; end
  class RateLimitError < Error; end
  class APIError < Error; end
end
```

### Immutable Value Objects

```ruby
# Freeze attributes after initialization
class SearchResult
  attr_reader :items, :total, :query

  def initialize(items:, total:, query:)
    @items = items.freeze
    @total = total
    @query = query.freeze
    freeze
  end
end
```

## Build and Release

```bash
# Install dependencies
bundle install

# Build gem locally
bundle exec rake build

# Install locally for testing
bundle exec rake install

# Release to RubyGems (bump version first in lib/exa/version.rb)
bundle exec rake release

# Run quality checks
bundle exec rubocop          # Style/lint
bundle exec bundle-audit     # Security
```

## Performance Considerations

- Keep Minitest suite fast (target <5s for full suite)
- Use `stub` and `mock` instead of real HTTP calls
- Lazy-load heavy dependencies
- Connection pooling for concurrent requests (future enhancement)
- Cache configuration reads

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
- Avoid heavy dependencies for simple tasks
- Pin major versions, allow minor/patch updates
- Regular dependency audits for security
