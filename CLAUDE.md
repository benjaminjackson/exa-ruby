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

spec/
├── exa-openapi-spec.yaml       # Full OpenAPI spec (reference)
├── components.yaml             # Shared schemas and types
├── endpoints/                  # Individual endpoint specs
│   ├── search.yaml
│   ├── findSimilar.yaml
│   ├── contents.yaml
│   ├── answer.yaml
│   ├── research_v1.yaml
│   └── research_v1_by_id.yaml
└── README.md                   # Spec documentation
```

## API Reference

**IMPORTANT**: When implementing any endpoint, ALWAYS reference the OpenAPI spec first.

### Using the OpenAPI Specs

The `spec/` directory contains the complete Exa API specification split into focused files:

**Quick Reference Workflow:**
1. **Start with the endpoint file** (`spec/endpoints/{endpoint_name}.yaml`)
   - See request parameters, types, and required fields
   - Review response structure and status codes
   - Check code examples in Python/JavaScript for naming conventions

2. **Reference components** (`spec/components.yaml`) for:
   - Detailed schema definitions (anything with `$ref: "#/components/..."`)
   - Common types like `SearchResult`, `Content`, error formats
   - Shared request/response structures

3. **Consult full spec** (`spec/exa-openapi-spec.yaml`) only when:
   - You need to see relationships between multiple endpoints
   - Endpoint files lack necessary context

**Example**: Implementing `/search` endpoint
```bash
# Read the search endpoint spec
# Focus on: requestBody.content.application/json.schema
# and: responses.200
head -200 spec/endpoints/search.yaml

# Check SearchResult schema definition
grep -A 50 "SearchResult:" spec/components.yaml
```

### Updating the Specs

Download latest from Exa's repository:
```bash
curl -s https://raw.githubusercontent.com/exa-labs/openapi-spec/refs/heads/master/exa-openapi-spec.yaml \
  -o spec/exa-openapi-spec.yaml

# Then re-run the extraction script (see spec/README.md)
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
def teardown
  # Reset config to avoid test pollution
  Exa.reset
end

def test_configuration
  Exa.configure do |config|
    config.api_key = "new_key"
  end

  assert_equal "new_key", Exa.api_key
end
```

### Using VCR for Integration Tests

```ruby
# Record real API interactions once, replay in tests
def test_search_integration
  VCR.use_cassette('search_ruby_programming') do
    client = Exa::Client.new(api_key: ENV['EXA_API_KEY'])
    result = client.search('ruby programming')

    assert_instance_of Exa::Resources::SearchResult, result
    refute_empty result.items
  end
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
  class TooManyRequests < ClientError; end     # 429 (rate limiting)

  # Server errors (5xx)
  class ServerError < Error; end
  class InternalServerError < ServerError; end # 500
  class BadGateway < ServerError; end          # 502
  class ServiceUnavailable < ServerError; end  # 503
  class GatewayTimeout < ServerError; end      # 504

  # Configuration errors
  class ConfigurationError < Error; end
end
```

### Resource Objects with Frozen Struct

```ruby
# Using Struct with freeze for immutability
module Exa
  module Resources
    class SearchResult < Struct.new(:results, keyword_init: true)
      def initialize(**)
        super
        freeze
      end

      def first = results.first
      def empty? = results.empty?

      def to_h
        { results: results }
      end
    end
  end
end

# Usage:
result = Exa::Resources::SearchResult.new(results: [...])
result.results # => [...]
result.results = [] # => raises FrozenError
```

### Connection Configuration with Timeouts

```ruby
# lib/exa/connection.rb
module Exa
  class Connection
    def self.build(api_key:, **options)
      Faraday.new(url: options[:base_url] || 'https://api.exa.ai') do |conn|
        # Authentication
        conn.request :authorization, 'Bearer', api_key

        # Request/Response handling
        conn.request :json
        conn.response :json, content_type: /\bjson$/

        # Logging (conditional)
        if options[:debug]
          conn.response :logger, Logger.new($stdout), headers: true, bodies: true
        end

        # Custom error handling
        conn.use Exa::Middleware::RaiseError

        # Timeouts (CRITICAL for production)
        conn.options.timeout = options[:timeout] || 30
        conn.options.open_timeout = options[:open_timeout] || 10

        # Adapter (allow override for testing)
        conn.adapter options[:adapter] || Faraday.default_adapter
      end
    end
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
- Require Ruby 3.0+ for modern syntax support
- Avoid heavy dependencies for simple tasks
- Pin major versions, allow minor/patch updates
- Regular dependency audits for security

## Key Dependencies

```ruby
# Runtime
gem 'faraday', '~> 2.0'

# Development & Testing
gem 'minitest', '~> 5.0'
gem 'webmock', '~> 3.0'
gem 'vcr', '~> 6.0'
gem 'rake', '~> 13.0'
```

## Implementation Checklist

When implementing a new API endpoint:

- [ ] **Read the OpenAPI spec** for the endpoint (`spec/endpoints/{name}.yaml`)
  - Review request parameters, types, and required fields
  - Note response schema and status codes
  - Check Python/JS examples for naming conventions
- [ ] Define the resource object using frozen Struct or plain class
- [ ] Write service object test with stubbed HTTP response
- [ ] Implement service object with `#call` method
- [ ] Add method to Client class
- [ ] Write integration test with VCR cassette
- [ ] Verify error handling (401, 404, 500, etc.)
- [ ] Update README with usage example
- [ ] Run full test suite to ensure no regressions
