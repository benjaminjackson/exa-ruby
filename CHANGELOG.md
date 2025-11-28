# Changelog

All notable changes to the exa-ai gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2025-11-26

### Added
- Updated search types to use `fast` and `deep` instead of deprecated types

### Changed
- Prioritized detailed error messages from API responses for better debugging
- CLI error messages now use $stderr instead of $stdout
- CLI output now flushes stdout to ensure piped output reaches destination immediately

### Fixed
- Corrected CLI help messages to reference `exa-ai` instead of `exa-api`
- Improved webset-create CLI test error handling

## [0.4.1] - 2025-11-26

### Changed
- Added comprehensive codebase patterns documentation for service objects, resources, and CLI commands
- Improved test coverage for webset-search CLI commands

## [0.4.0] - 2025-11-23

### Added

#### Websets API Support
- **Complete Websets CRUD operations** - Full implementation of Websets API with create, retrieve, list, update, delete, and cancel operations
- **Webset Searches** - Create, retrieve, and cancel searches within websets with entity type support, custom criteria, and recall modes
- **Webset Items** - List, retrieve, and delete items in websets with expand parameter support
- **Webset Enrichments** - Full CRUD operations for enrichments with support for text, URL, and options formats
- **Parameter validation** - Client-side validation for webset creation and search operations with custom entity type support
- **Resource expansion** - Optional expand parameter to include nested resources (e.g., items) in webset responses

#### CLI Enhancements
- **Webset commands** - Complete CLI interface for websets (create, get, list, update, delete, cancel)
- **Webset search commands** - CLI for search operations (create, get, cancel) with wait flag for polling
- **Webset item commands** - CLI for item operations (list, get, delete)
- **Enrichment commands** - Full CLI suite for enrichments (create, get, list, update, delete, cancel)
- **Find similar command** - New CLI command for finding content similar to a URL
- **Improved help output** - Organized command categories with examples for better discoverability
- **File loading support** - Support for @file.json syntax in CLI for loading JSON parameters from files

#### Testing Infrastructure
- **WebsetsCleanupHelper** - Automatic resource cleanup for integration tests to prevent test interference
- **Minitest fail-fast** - Added minitest-fail-fast gem for faster test development workflow
- **Comprehensive integration tests** - Full test coverage for websets, searches, items, and enrichments (536+ tests)
- **Improved test queries** - Updated to use realistic, domain-specific queries instead of generic placeholders
- **VCR improvements** - Better cassette management with :once record mode to prevent unnecessary API calls

#### Infrastructure
- **WebsetsParameterConverter** - Snake_case to camelCase conversion for webset parameters
- **WebsetFormatter** - Output formatting for websets in json/pretty/text formats
- **EnrichmentFormatter** - Output formatting for enrichments with status helper methods
- **WebsetItemFormatter** - Formatting for individual webset items
- **Cursor-based pagination** - Support for cursor-based pagination in webset listing

### Changed
- **Test development workflow** - Updated guidelines for when to run full test suite vs. single tests
- **VCR configuration** - Changed from :new_episodes to :once mode to prevent accidental API token usage
- **Authentication** - Uses x-api-key header (carried forward from 0.3.1)

### Fixed
- **Test isolation** - Improved EXA_API_KEY handling with proper preservation and restoration
- **Test data realism** - Fixed API errors by using realistic queries instead of generic test data
- **CLI integration tests** - Converted to smoke tests with proper API key handling
- **VCR cassette recording** - Fixed debug logging contamination in VCR cassettes
- **Enrichment format support** - Updated to use supported formats (text, url, options) and removed unsupported email/phone formats

## [0.3.1] - 2025-10-28

### Added

#### CLI Features
- **Answer formatter** - New answer formatter module imported into CLI for improved answer output formatting

#### Testing
- **CLI executable tests** - Comprehensive test suite validating CLI executables and their functionality

### Changed
- **Authentication header** - Migrated from Bearer token authentication to x-api-key header for API requests (internal change, no user-facing impact)

### Fixed
- **Gem name conflict** - Resolved conflict with unrelated 'exa' gem to ensure proper gem resolution

## [0.3.0] - 2025-10-20

### Added

#### Answer Endpoint Enhancements
- **Streaming support** - `--stream` flag to stream answers as they're generated
- **System prompt support** - `--system-prompt` flag for custom answer instructions

#### Research CLI Enhancements
- **Model selection** - Updated `research-start` command with model options

#### Get Contents CLI Enhancements
- **Advanced parameters** - Expanded `get-contents` command with additional content extraction options

### Changed
- N/A

### Fixed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Security
- N/A

## [0.2.0] - 2025-10-19

### Added

#### Advanced Search Features
- **Date range filtering** - Filter search results by publication date and crawl date:
  - `start_published_date` / `end_published_date` - Results published within date range
  - `start_crawl_date` / `end_crawl_date` - Results crawled within date range
- **Text filtering** - Include and exclude results based on text content:
  - `include_text` - Results must contain specified phrase
  - `exclude_text` - Results must not contain specified phrase
- **Full webpage text extraction** - Retrieve and process full page content:
  - Boolean or advanced configuration with `max_characters` and `include_html_tags`
  - Configurable character limits for API cost control
  - Optional HTML tag preservation for LLM compatibility
- **AI-powered summaries** - Generate structured summaries with custom prompts and schemas:
  - Custom summary prompts for tailored LLM instructions
  - JSON schema support for structured output
  - Full customization of summary format and content
- **Context formatting for RAG** - Format results as context strings for LLM retrieval-augmented generation:
  - Automatic context string generation from search results
  - Configurable character limits
- **Subpage crawling** - Extract content from related subpages:
  - Specify number of subpages to crawl
  - Fuzzy text matching for subpage targeting (e.g., "about", "docs", "pricing")
- **Links and image extraction** - Extract URLs and image URLs from results:
  - Configurable count per result
  - Separate image link extraction

#### Parameter Conversion Infrastructure
- **ParameterConverter** - Dedicated service for converting Ruby parameters to API format:
  - Snake_case to camelCase conversion
  - Nested content parameter handling
  - Reusable component for future parameter transformations

#### CLI Enhancements
- Comprehensive date range flags: `--start-published-date`, `--end-published-date`, `--start-crawl-date`, `--end-crawl-date`
- Text filtering flags: `--include-text`, `--exclude-text` (repeatable)
- Content extraction flags:
  - Text: `--text`, `--text-max-characters`, `--include-html-tags`
  - Summary: `--summary`, `--summary-query`, `--summary-schema` (with @file syntax)
  - Context: `--context`, `--context-max-characters`
  - Subpages: `--subpages`, `--subpage-target` (repeatable)
  - Links: `--links`, `--image-links`
- Enhanced help text with organized option categories
- JSON schema file loading with `@filename` syntax

#### Testing
- 9 new comprehensive integration tests covering all search features
- Tests for individual features and multi-feature combinations
- Parameter conversion validation tests

#### Documentation
- Extended README with advanced search examples
- Complete CLI usage documentation for all new flags
- Ruby API examples for all new features
- Usage patterns for combining multiple features

### Changed
- Search command help text reorganized for clarity
- Parameter handling through centralized ParameterConverter

### Fixed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Security
- N/A

## [0.1.0] - 2025-10-19

### Added

#### API Features
- **Search endpoint** - Full-featured web search with query, type filters, include/exclude domains, and pagination
- **Answer endpoint** - Direct answers for queries
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
