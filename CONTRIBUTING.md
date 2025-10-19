# Contributing to exa-ai

Thank you for your interest in contributing to the exa-ai gem! This document provides guidelines and instructions for development.

## Development Setup

### Prerequisites
- Ruby 3.0 or higher
- Bundler

### Getting Started

1. Clone the repository
```bash
git clone https://github.com/benjaminjackson/exa-ruby.git
cd exa-ruby
```

2. Install dependencies
```bash
bundle install
```

3. Set up your environment (optional)
```bash
export EXA_API_KEY="your-api-key"
```

## Running Tests

### Run the full test suite
```bash
bundle exec rake test
```

### Run specific test file
```bash
bundle exec ruby test/services/search_test.rb
```

### Run tests with pattern matching
```bash
bundle exec rake test TEST="test/services/*_test.rb"
```

### Run single test by name
```bash
bundle exec ruby test/services/search_test.rb -n test_search_returns_results
```

### Run tests with verbose output
```bash
bundle exec rake test TESTOPTS="-v"
```

## Code Conventions

### Ruby Style
- Follow Ruby conventions and idioms
- Use Ruby 3.0+ features (keyword arguments, pattern matching, endless methods)
- Prefer self-documenting code over comments
- Reference [CLAUDE.md](./CLAUDE.md) for architecture patterns

### Testing (TDD)
- Write tests before implementation (red-green-refactor)
- Use descriptive test names: `test_search_raises_error_when_query_missing`
- Follow Arrange-Act-Assert structure
- One assertion per test (generally)
- Use minitest assertions:
  - `assert_equal`, `assert_nil`, `assert_empty`, `assert_includes`
  - `refute_equal`, `refute_nil`, `refute_empty`
  - `assert_raises` for error testing
  - `assert_instance_of` for type checking

### Commits
- Use conventional format: `<type>(<scope>): <subject>`
- Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`
- Subject: 50 chars max, imperative mood ("add" not "added"), no period
- For complex changes: add body explaining what/why (72-char lines)
- Keep commits atomic (one logical change per commit)

### Documentation
- Add YARD docs for public methods (`@param`, `@return`, `@example`)
- Update README.md with usage examples for new features
- Reference the OpenAPI spec in spec/ when implementing new endpoints

## Adding New API Endpoints

1. **Check the OpenAPI spec** first
   - Read `spec/endpoints/{endpoint_name}.yaml` for request/response structure
   - Check `spec/components.yaml` for schema definitions

2. **Create resource object** (if needed)
   - Use frozen Struct or plain class for immutability
   - Add helper methods for common operations
   - Implement `#to_h` for serialization

3. **Write tests first** (`test/services/{endpoint}_test.rb`)
   - Stub HTTP requests with WebMock
   - Test success and error cases
   - Verify correct API endpoint and parameters

4. **Implement service object** (`lib/exa/services/{endpoint}.rb`)
   - Constructor takes connection and parameters
   - Single public `#call` method returns resource object
   - Minimal business logic

5. **Add to Client class** (`lib/exa/client.rb`)
   - Add delegating method with YARD docs
   - Follow existing method naming conventions

6. **Add integration test** (optional)
   - Use VCR cassette for recorded HTTP interactions
   - Test real API contract with response validation

7. **Update README.md**
   - Add usage example in Ruby API section
   - Add CLI command documentation if applicable

## Testing Strategy

### Unit Tests
- Test single class in isolation
- Mock external dependencies (HTTP calls)
- Fast (<1ms per test)
- Location: `test/services/`, `test/` root

### Integration Tests
- Test multiple components working together
- Stub HTTP responses with VCR cassettes
- Slower but verify contract between components
- Location: `test/integration/`

### Test Configuration
- WebMock is configured to prevent real HTTP calls
- VCR records/replays HTTP interactions
- API keys are filtered from cassettes for security
- Test helper: `test/test_helper.rb`

## Build and Quality

### Build locally
```bash
bundle exec rake build
```

### Install locally for testing
```bash
bundle exec rake install
```

### Security audit
```bash
bundle exec bundle-audit check
```

### Generate documentation
```bash
bundle exec yardoc
```

## Release Process

### Prerequisites
- All tests passing
- No security vulnerabilities
- Documentation up to date
- CHANGELOG.md updated

### Release Checklist

1. **Verify readiness**
   ```bash
   # Run all tests
   bundle exec rake test

   # Build locally
   bundle exec gem build exa-ai.gemspec

   # Security audit
   bundle exec bundle-audit check
   ```

2. **Prepare release commit** (if not already done)
   ```bash
   # Update version in lib/exa/version.rb if needed
   # Update CHANGELOG.md with new version notes

   git add -A
   git commit -m "chore(release): Prepare vX.Y.Z"
   ```

3. **Create GitHub release with gh CLI**
   ```bash
   # This creates git tag, GitHub release, and uploads gem artifact
   gh release create vX.Y.Z \
     --title "vX.Y.Z - <Release Title>" \
     --notes-file CHANGELOG.md \
     exa-ai-X.Y.Z.gem
   ```

4. **Publish to RubyGems**
   ```bash
   gem push exa-ai-X.Y.Z.gem
   ```

5. **Verify release**
   ```bash
   # Verify on RubyGems.org
   gem list -r exa-ai

   # View GitHub release
   gh release view vX.Y.Z
   ```

### Troubleshooting Releases

**Gem build fails**
- Check that exa.gemspec files list includes all necessary files
- Verify no uncommitted changes in tracked files
- Run `bundle exec rake build` with verbose output

**GitHub release creation fails**
- Verify `gh` CLI is installed and authenticated: `gh auth status`
- Check gem file exists: `ls -la exa-ai-*.gem`
- Ensure you have push access to repository

**RubyGems publish fails**
- Verify credentials: `gem signin` or check `~/.gem/credentials`
- Check version is not already published: `gem list -r exa-ai`
- Ensure gem builds locally first

## Questions or Issues?

- Check existing tests for patterns and examples
- Review [CLAUDE.md](./CLAUDE.md) for architecture decisions
- Read OpenAPI specs in `spec/` for API details
- Check README.md for usage examples

## Code of Conduct

Contributors are expected to be respectful and constructive in all interactions.

---

Thank you for contributing to exa-ai! 🙏
