# Changelog

All notable changes to the exa-ai gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-10-19

### Added

#### API Features
- **Search endpoint** - Full-featured web search with query, type filters, include/exclude domains, and pagination
- **Answer endpoint** - Direct answers and autoprompt synthesis for queries
- **Context endpoint** - Code search with language filtering and file type support
- **Get Contents endpoint** - Retrieve full page contents from URLs
- **Research endpoints** - Async research operations:
  - `start_research` - Begin long-running research tasks
  - `get_research` - Check research task status and results
  - `list_research` - List all research tasks

#### Configuration Options
- Multiple configuration methods:
  - Environment variable (`EXA_API_KEY`)
  - Configuration block (`Exa.configure`)
  - Per-request API key flag
- Customizable timeouts and connection options
- Debug logging support

#### CLI Tools (8 commands)
- `exa search` - Execute search queries from command line
- `exa answer` - Get AI-generated answers
- `exa context` - Search code repositories
- `exa contents` - Fetch full page contents
- `exa research start` - Begin async research
- `exa research get` - Check research results
- `exa research list` - List active research tasks
- `exa version` - Display gem version

#### CLI Features
- Multiple output formats (JSON, table, JSONL)
- Structured output support with `--output-schema` flag
- Text rendering for human-readable results
- Proper error messages and exit codes

#### Infrastructure
- Full error hierarchy (Client, Server, Configuration errors)
- HTTP client built on Faraday with:
  - Bearer token authentication
  - JSON request/response handling
  - Configurable timeouts
  - Custom error middleware
  - Debug logging support
- Resource objects (immutable Structs) wrapping API responses
- Comprehensive test suite (339 tests)
- VCR integration for deterministic testing
- WebMock for stubbed HTTP responses

#### Documentation
- Comprehensive README with installation and usage examples
- Inline code documentation following Ruby conventions
- Project architecture guide (CLAUDE.md)
- OpenAPI specification files for reference
- Test helper setup for development

### Fixed
- N/A (initial release)

### Deprecated
- N/A (initial release)

### Removed
- N/A (initial release)

### Security
- API keys filtered from VCR cassettes
- No hardcoded credentials
- Bearer token authentication properly configured
- Dependency security scanning recommended

## Future Releases

- YARD documentation for public API
- GitHub Actions CI/CD pipeline
- Additional language support in CLI examples
