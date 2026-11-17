# Changelog

All notable changes to the exa-ai gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Monitors API** - `search_monitor_create`, `_list`, `_get`, `_update`, `_delete`, `_trigger`, `_batch`, `_runs_list` and `_runs_get` cover the `/monitors` API: scheduled searches that post new results to a webhook. CLI commands `exa-ai search-monitor-*`. This is a different product from Websets monitors (`create_monitor`, `exa-ai monitor-*`), which are unchanged
- **Agent run errors** - `AgentRun#error` holds the `{type, code, message}` the API returns for a failed run, and `to_h` includes it. The CLI prints it for a failed run
- **`lite` and `deep-lite` search types** - `search(type: "lite")` and `type: "deep-lite"`, also on `exa-ai search --type`. `lite` accepts only a limited set of parameters; the API rejects a request with any other
- **Search warnings, notices and search time** - `SearchResult#warnings`, `#notices` and `#search_time`; `ContentsResult#search_time` and `FindSimilarResult#search_time`. `exa-ai search` prints each warning to stderr as `Warning: <message> (<path>)` and shows notices in `pretty` and `text` output
- **`Answer#request_id`** - from the API's `requestId`, also in `to_h`
- **New content options** - `snapshot_as_of` and `crawled_before_date` on search and find-similar go under `contents`. New flat keys `text_link_style`, `text_include_sections`, `text_exclude_sections`, `highlights_verbosity`, `highlights_dynamic` and `rich_image_links` fold under `text`, `highlights` and `extras`
- **Dynamic highlights header** - when a request sets `highlights.dynamic` or `highlights.verbosity`, `search`, `find_similar`, `get_contents` and `search_stream` send the header `Exa-Beta: dynamic-highlights-2026-08-28`, which the API requires for these options
- **`search_stream`** - `client.search_stream(query, output_schema:, **params) { |chunk| ... }` yields each server-sent event (`text-delta`, `grounding`, `results`, `stream-reset`, `done`). It requires `output_schema`, because the API streams search only with one. An `error` event raises `Exa::Error`
- **Answer stream errors** - an `ERROR` event in an `answer_stream` raises `Exa::Error` with the API's message
- **`get_contents` with document IDs** - `client.get_contents(ids: [...])` sends only `ids`; `urls` is sent only when given
- **`exa-ai search` flags** - `--objective`, `--user-identifier`, `--compliance hipaa` and `--snapshot-as-of`. `--user-location` also takes a JSON object (`{"country":"US","latitude":...,"longitude":...}`) or `@file`
- **`exa-ai get-contents` flags** - `--ids`, `--max-age-hours`, `--snapshot-as-of`, `--user-identifier`, `--compliance`, `--highlights`, `--highlights-query`, `--highlights-max-characters`, `--highlights-verbosity` and `--text-verbosity`. URLs are optional when `--ids` is given
- **`exa-ai answer` flags** - `--model` (`exa`, `exa-pro`, `exa-research`, `exa-fast`), `--user-location` and `--user-identifier`, with and without `--stream`
- **Stop an agent run** - `agent_run_stop` and `exa-ai agent-run-stop` call `POST /agent/runs/{id}/stop`. The run completes with stop reason `stopped` and keeps its results. The API supports it only for effort `high`, `xhigh` and `ultra`
- **Agent run budget, metadata and user flags** - `exa-ai agent-run-create` takes `--max-cost-dollars`, `--max-duration-seconds`, `--metadata` and `--user-identifier`
- **Agent run event replay** - `agent_run_events(run_id, last_event_id: "7")` replays the events after that id over server-sent events and returns the same `AgentRunEventList`
- **Event pages on the CLI** - `exa-ai agent-run-events` takes `--limit` and `--cursor`
- **More agent run output** - pretty and text output show the stop reason of a completed run. Pretty output also shows the cost of each data source, usage, and the field and confidence of each grounding item
- **Status helpers for every spec status** - `Monitor#enabled?`, `#disabled?`; `Webset#pending?`, `#running?`, `#paused?`; `WebsetEnrichment#canceled?`; `WebsetSearch#pending?`; `MonitorRun#created?`, `#canceled?`; `Import#canceled?`

### Changed
- **`--category github` rejected** - `exa-ai search` and `exa-ai find-similar` no longer accept `--category github`, which is not in the API's category list. The Ruby client still sends any category it is given
- **`agent_run_delete` returns `Exa::Resources::AgentRunDeletion`** - The API answers a delete with `{id, object: "agent_run.deleted", deleted: true}`. Use `#deleted?` and `#id`. Before, the method returned an `AgentRun` whose status was nil

### Fixed
- **Flat content keys on `get_contents`** - flat keys such as `text_max_characters`, `summary_schema` and `highlights_verbosity` now fold under `text`, `summary` and `highlights`, as on `search`. Before, `get_contents` sent them at the top level, where the API does not know them. A flat `highlights_verbosity` now sends the `Exa-Beta` header, and a flat `summary_schema` now gives parsed JSON summaries
- **Content options in any order** - `text_max_characters: 500, text: true` sends `text: {maxCharacters: 500}`. Before, a flat key given before its parent key was dropped
- **Caller's own `contents` hash** - on `search`, `find_similar`, `search_stream`, agent runs and search monitors, it now merges with flat content keys at every depth, so `contents: {text: {max_characters: 5}}, text: true` keeps `max_characters`. A `"contents"` String key now merges into the same `contents` key; before, it gave two keys and JSON encoding raised a duplicate key error
- **Agent run stream parsing** - the stream reads the `id:` line and passes it to the block as a third argument (blocks and procs that take two arguments keep working; a lambda must accept three), accepts `\r\n` line endings and fields with no space after the colon, and skips comment lines
- **Exa Connect provider slugs** - the CLI help and README use the documented slugs `fiber` and `particle` (not `fiber_ai` and `particle_news`) and list `polymarket` and `macrobond`
- **`agent-run-create --wait` limit** - when the stream drops, polling now waits up to 3 hours (the longest an `ultra` run can take) instead of 5 minutes
- **`--effort` help includes `ultra`**
- **camelCase request keys for contents, find-similar, answer, context and agent runs** - `get_contents`, `find_similar`, `answer`, `answer` streaming and `context` now send camelCase keys (for example `systemPrompt`, `outputSchema`, `subpageTarget`, `tokensNum`), and nested keys are converted too (for example `budget.maxCostDollars` on agent runs). Keys inside `outputSchema`, `schema`, `metadata`, `data` and `exclusion` are sent as given
- **find-similar content options** - `text` and `summary` go under `contents`, as the spec requires
- **`exa-ai get-contents` option values** - an option that takes a value no longer has its value read again as the URL argument when the option comes before the URL
- **`WebsetSearch#in_progress?` with status `pending`** - a search with status `pending` is now in progress, as are `created` and `running`

### Deprecated
These still work. Help text, doc comments, README and docs now mark them with their replacements
- **`find_similar` and `exa-ai find-similar`** - the API deprecates `/findSimilar`. Use `search` with a query that describes the source page
- **`context` and `exa-ai context`** - `/context` is not in the API spec. No replacement is named; for code lookup, use `search`
- **Legacy search types** - `fast` and `instant` (use `lite`), `deep-reasoning` (use `deep`) and `neural` (not in the spec)
- **`start_crawl_date` and `end_crawl_date`** - the API ignores them and returns an `IGNORED_FIELD` warning
- **`include_text` and `exclude_text`**
- **The `context` contents option and `context` response field** - use `highlights` or `text`
- **`highlights` `num_sentences` and `highlights_per_url`** - use `max_characters`; the API ignores `highlights_per_url`
- **`subpages` and `subpage_target` on `search` and `find_similar`** - they stay valid on `get_contents`
- **`resolved_search_type`** - may be an empty string; `search_type` is not in the API spec

## [0.13.0] - 2026-11-16

### Removed
- **Research API support** - Removed the `research_start`, `research_list` and `research_get` client methods and the `exa-ai research-start`, `research-get` and `research-list` commands. Exa retired the Research API (it now returns HTTP 410). Use the Agent API instead (`agent_run_create(query: ...)`, `exa-ai agent-run-create --query ...`)

### Fixed
- **Unmapped error statuses now raise** - Any 4xx or 5xx status without its own error class (for example 405, 409, 410, 501) now raises `Exa::ClientError` or `Exa::ServerError` with the API's message. Before, these responses returned as if the request worked, and callers got resources with nil fields. Code that relied on that silent return must now rescue the error
- **Streaming errors keep the API message** - `answer` streaming and agent run streaming now show the error message from the API, not only `HTTP <status>`
- **Failed import file uploads now raise** - `UploadImport` raises when the PUT to the upload URL fails (for example an expired URL). Before, it reported success

## [0.12.2] - 2026-07-23

### Fixed
- **`tweet` category removed** - The Exa API now rejects `category: "tweet"` with a hard error, so `exa-ai search` and `exa-ai find-similar` no longer accept or advertise it. Valid categories are: company, publication, news, github, personal site, people, financial report

### Changed
- **`--output-schema` note in help text** - `deep` and `deep-reasoning` searches no longer auto-synthesize the `output` field; the API returns it only when an output schema is supplied. The `--type` and `--output-schema` help now say so
- **Shared category list** - `exa-ai find-similar` references `Exa::CLI::SearchParser::VALID_CATEGORIES` instead of keeping a hand-synced copy

## [0.12.1] - 2026-06-29

### Fixed
- **`--effort` help text** - Corrected the listed values to match the full API set: `minimal, low, medium, high, xhigh, auto` (was missing `minimal`, `xhigh`, and `auto`)

## [0.12.0] - 2026-06-29

### Added
- **Agent API** - Full support for Exa's Agent Run API: create, list, get, delete, and stream agent runs (`client.create_agent_run`, `client.list_agent_runs`, `client.get_agent_run`, `client.delete_agent_run`)
- **AgentRun resource** - New `Exa::Resources::AgentRun` and `Exa::Resources::AgentRunList` resource objects wrapping agent run API responses
- **CLI agent-run commands** - New `exa agent-run create`, `agent-run list`, `agent-run get`, and `agent-run delete` subcommands
- **Live streaming** - `exa agent-run create --wait` streams events in real time with live status updates
- **Structured output & grounding** - CLI renders structured output and grounding sources from agent run responses
- **Exa Connect data sources** - `--input-data` flag on `agent-run create` to pass Exa Connect data sources (websets, web streams)
- **Input exclusion** - `--input-exclusion` flag to exclude specific domains or URLs from agent runs
- **Previous run chaining** - `--previous-run-id` flag to chain an agent run to a prior one for iterative workflows

## [0.11.2] - 2026-05-03

### Fixed
- **PaymentRequired error** - Middleware now raises `Exa::PaymentRequired` on 402 responses instead of a generic error

## [0.11.1] - 2026-03-20

### Fixed
- **Structured summary parsing** - When `summary: { schema: ... }` is provided, the gem now automatically parses the JSON-encoded summary string returned by the API into a Ruby Hash. Plain text summaries (no schema) are unchanged.

### Changed
- **Parameter consolidation** - Flat content sub-parameters (e.g., `text_max_characters`, `highlights_query`) are now automatically nested under their parent hashes before conversion, simplifying CLI integration

## [0.11.0] - 2026-03-19

### Added
- **Text verbosity** - Added `--text-verbosity` CLI flag with `compact`, `standard`, and `full` options for controlling text extraction detail level
- **System prompt** - Added `--system-prompt` CLI flag and `system_prompt` parameter (converts to `systemPrompt`) for AI-powered search customization
- **Content moderation** - Added `--moderation` CLI flag to enable content moderation on search results

### Changed
- **Livecrawl flag** - `--livecrawl` is now a boolean flag (was a mode string). Enables livecrawl with smart defaults: `maxAgeHours=0` and `livecrawlTimeout=5000`. Use `--livecrawl-timeout` and `--max-age-hours` to override defaults

### Fixed
- **Category list** - Removed deprecated `pdf` category from valid categories

## [0.10.0] - 2026-03-07

### Added
- **Livecrawl support** - Added `livecrawl` and `max_age_hours` parameters to search, with CLI `--livecrawl` and `--max-age-hours` flags
- **Deep-reasoning search type** - Added `deep-reasoning` and `instant` search types alongside existing types
- **Output field** - Search results now include an `output` field for deep-reasoning responses
- **Additional search parameters** - Added `additional_queries`, `output_schema`, and `user_location` parameter conversions
- **Integration tests** - Comprehensive integration tests for post-v0.9.0 search features including deep-reasoning

### Fixed
- **Parameter conversion** - `num_results`, `include_domains`, `exclude_domains`, and highlights now correctly convert to camelCase in request body
- **CLI search parser** - Updated to support current API search types (`auto`, `fast`, `deep`, `neural`, `instant`, `deep-reasoning`)
- **Livecrawl validation** - Added proper validation for livecrawl parameter values in CLI
- **User location** - Use ISO country code format per API spec
- **VCR cassettes** - Re-recorded search cassettes against live API for accuracy

## [0.9.0] - 2026-02-24

### Added
- **Webset title support** - Websets can now be created and updated with an optional `title` field via both the Ruby client and CLI (`--title` flag on `webset-create` and `webset-update`)

### Fixed
- **Integration test stability** - Added pre/post-suite sweep of stale websets to prevent hitting concurrent webset API limits during test runs

## [0.8.0] - 2026-02-13

### Added
- **Automatic .env file loading** - CLI and library now automatically load environment variables from .env files, eliminating the need to manually set EXA_API_KEY environment variable

### Changed
- **dotenv dependency** - Moved dotenv from development to runtime dependency to support automatic .env file loading

## [0.7.2] - 2026-02-13

### Changed
- **Removed native extension dependency** - Removed unused `ld-eventsource` dependency, eliminating FFI and native compilation requirements

### Fixed
- **CLI improvements** - Corrected cursor field name in webset-list help text, improved dispatcher executable handling
- **Search defaults** - Changed default search type to `auto` for better results

## [0.7.1] - 2026-01-20

### Added
- **Answer command --skip-citations flag** - Added `--skip-citations` and `--no-citations` flags to the answer command to omit citations from output, saving tokens when citations aren't needed

### Changed
- **Documentation improvements** - Added Ruby requirements and macOS setup instructions, simplified table of contents
- **Test improvements** - Enhanced CLI integration test error messages, made setup commands fail fast instead of skip, improved handling of missing API keys

## [0.7.0] - 2026-01-13

### Added
- **Search categories** - Added support for people and company categories in search command

### Changed
- **CLI argument parsing** - Refactored search command argument parsing into reusable module
- **LinkedIn workaround removed** - Removed legacy LinkedIn-specific workaround

## [0.6.1] - 2025-12-07

### Changed
- **Enhanced pretty format output** - Replaced JSON.pretty_generate with human-readable text format across all CLI formatters for better readability

### Fixed
- **CLI enrichment flags** - Removed unused enrichment flags that were causing confusion
- **Webset import/search scope validation** - Added proper validation to prevent conflicts between import and search scope parameters
- **CLI formatter test** - Fixed enrichment CLI integration test to properly handle pretty format output (text instead of JSON)
- **Test cleanup** - Improved webset cleanup in tests to cancel all searches before deletion, preventing concurrent request limit issues

## [0.6.0] - 2025-11-28

### Added

#### Webset Imports
- **Import API operations** - Full support for creating and managing webset imports from CSV files
- **File upload service** - Service for uploading CSV files to create websets from external data
- **Import resource objects** - Resource objects for handling import responses and status
- **Import CLI commands** - Complete CLI interface for import operations (create, list, get)
- **Create websets from imports** - Direct webset creation from import results

#### Webset Monitors
- **Monitor API operations** - Comprehensive support for creating, retrieving, listing, updating, and deleting webset monitors
- **Monitor resource objects** - Resources for handling monitor configurations and schedules
- **Monitor CLI commands** - Full CLI suite for monitor operations (create, get, list, update, delete)
- **Automated webset updates** - Schedule periodic searches to keep websets up-to-date

#### CLI Enhancements
- **TOON output format** - New output format option for CLI commands supporting TOON serialization

### Changed
- **Entity type validation** - Refactored and consolidated entity type validation logic across webset operations

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
